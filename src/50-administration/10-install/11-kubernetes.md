## Install Kubernetes

Kubernetes can be installed through a number of cloud providers.

It can also be installed locally with [k3s](https://github.com/k3s-io/k3s) or even simpler with [k3d](https://k3d.io/stable/) which deploys k3s on a single node with Docker.

## K3D Install
Create the k3d configuration file: `config.yaml`.
```yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: maayanlab
servers: 1
agents: 1
volumes:
# a persistent volume we set up
- volume: /export/volgrp01/:/var/lib/rancher/k3s/storage
  nodeFilters:
  - all
ports:
  - port: 443:443
    nodeFilters:
    - loadbalancer
```

Then k3d is started with
```bash
k3d cluster create --config=config.yaml
```

## K3S Install on Bare Metal

The cluster is run with k3s, a lightweight kubernetes distribution by the creators of Rancher. It comes pre-installed with:
- traefik -- the ingress provider running on all nodes
- Helm CRDs -- allowing you to deploy helm charts as kubernetes resources (the `helm install` command happens via a job run by the cluster)

### Installing Base System On RedHat Linux

```bash
# the ip of the node we're configuring
NODE_IP=146.203.151.176
# common secret token across all nodes
KUBE_TOKEN=
# ip/hostname of one of the controlplane nodes already in the cluster
BOOTSTRAP_HOST="<FIRST_NODE_IP> <FIRST_NODE_HOSTNAME>"

# configure time (IMPORTANT!) -- the ips here are specific internals to the sinai network
vim /etc/chrony.conf
pool 10.94.8.20 iburst
pool 10.95.16.20 iburst

# disable firewall (IMPORTANT!)
systemctl disable --now firewalld

# install some core dependencies
sudo dnf -y install curl docker

# configure & start kube-haproxy
echo "${NODE_IP} kube-haproxy.local" >> /etc/hosts
mkdir -p /etc/haproxy /var/lib/kube-haproxy
echo "${BOOTSTRAP_HOST}" > /var/lib/kube-haproxy/hosts
mkdir -p /etc/rancher/k3s
touch /etc/rancher/k3s/k3s.yaml
docker run \
  --restart=unless-stopped \
  --name=kube-haproxy \
  --network=host \
  -v /etc/hosts:/etc/hosts:ro \
  -v /etc/rancher/k3s/k3s.yaml:/root/.kube/config:ro \
  -v /etc/haproxy:/etc/haproxy \
  -v /var/lib/kube-haproxy:/var/lib/kube-haproxy \
  -d \
  maayanlab/kube-haproxy:0.1.3

# configure and start k3s
mkdir -p /etc/rancher/k3s
cat > /etc/rancher/k3s/config.yaml << EOF
node-ip: '${NODE_IP}'
token: '${KUBE_TOKEN}'
write-kubeconfig-mode: '0644'
tls-san:
- 'kube-haproxy.local'
server: https://kube-haproxy.local:6445
flannel-backend: host-gw

# all false for controlplane, all true for worker
disable-apiserver: false
disable-controller-manager: false
disable-scheduler: false
disable-etcd: false
EOF
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_SELINUX_RPM=true sh -s - server
```

### Automatic Updates with K3s Upgrade Controller

https://docs.k3s.io/upgrades/automated

```bash
kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/latest/download/crd.yaml -f https://github.com/rancher/system-upgrade-controller/releases/latest/download/system-upgrade-controller.yaml

kubectl apply -f - << EOF
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: server-plan
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: In
      values:
      - "true"
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
  channel: https://update.k3s.io/v1-release/channels/stable
  window:
    days:
      - sunday
    startTime: 9:00
    endTime: 11:00
    timeZone: UTC
---
# Agent plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: agent-plan
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
  prepare:
    args:
    - prepare
    - server-plan
    image: rancher/k3s-upgrade
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
  channel: https://update.k3s.io/v1-release/channels/stable
  window:
    days:
      - sunday
    startTime: 9:00
    endTime: 11:00
    timeZone: UTC
EOF
```
