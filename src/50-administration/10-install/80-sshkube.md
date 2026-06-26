# sshkube

This is a trick we came up with to manage access to kubernetes over SSH served over TLS.

This simplifies accessing and managing access to our cluster(s).

A set of github usernames are defined, their github identity public keys are used to grant them access.
The sshkube python cli configures their ssh connection over https to the cluster, authenticating with their github identity.
A kube.conf file is transfered over to them and they can access the cluster via an ssh-facilitated SOCKS proxy.

From a user standpoint they just use `sshkube install -s ssh.ourdomain.com -u their-username`
and can subsequently access the cluster with `sshkube run kubectl ...`

<https://github.com/u8sand/sshkube>

## Install

```bash
# install the sshkube chart
#   users specified line-by-line in githubUsers will be able to authenticate against the cluster
#   storage is used for ssh host keys persistence
#   ingress is used to forward ssl connections to the given domain to the ssh server

kubectl apply -f - << EOF
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: sshkube
  namespace: kube-system
spec:
  targetNamespace: kube-system
  failurePolicy: reinstall
  repo: https://maayanlab.github.io/helm-charts
  chart: sshkube
  valuesContent: |
    ingress:
      type: traefik
      domain: ssh.k8s.maayanlab.cloud
      certResolver: default
    storage:
      class: rclone-s3-k8s-maayanlab-cloud
    # TODO: include other users
    githubUsers: |
      u8sand
EOF
# by default, users you configure will be given a namespace and exclusive access to that namespace
# cluster admins can give the user broader access if necessary, e.g.
kubectl create clusterrolebinding u8sand --clusterrole=cluster-admin --serviceaccount=u8sand:u8sand
```
