## Install Ma'ayanlab K8s

Besides the base kubernetes cluster, our team has developed several kubernetes extensions to make working with kubernetes easier.

## Configure Ingress for TLS Termination
If deploying with k3s/k3d, traefik will already be configured. If not you'll need to deploy that as well to your kubernetes cluster. You should then configure traefik for TLS termination (i.e. https), here is how you would do it with the k3d deployment:

Update the email below:
```bash
kubectl apply -f - << EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    additionalArguments:
      - "--certificatesresolvers.default.acme.email=YOUREMAIL@EXAMPLE.COM"
      - "--certificatesresolvers.default.acme.storage=/data/acme.json"
      - "--certificatesresolvers.default.acme.tlschallenge=true"
    ports:
      websecure:
        exposedPort: 443
EOF
```

## Deploy our in-house `kubernetes-auto-ingress`
This service is used a lot in the lab, it lets us easily configure `Ingress` resources without having to make them explicitly just by marking the desired route on the deployment/service.

```bash
helm repo add maayanlab https://maayanlab.github.io/helm-charts
helm repo update maayanlab
helm upgrade -n kube-system kubernetes-auto-ingress maayanlab/kubernetes-auto-ingress -f - << EOF
rbac:
  create: true
serviceAccount:
  create: true
annotationKey: maayanlab.cloud/ingress
ingressClassName: traefik
ingressCreateTLS: false
extraAnnotations:
  http:
    ingress:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
  https:
    ingress:
      traefik.ingress.kubernetes.io/router.entrypoints: websecure
      traefik.ingress.kubernetes.io/router.tls.certresolver: default
watchNamespace: '*'
EOF
```

The custom config above is set up so that it works with the traefik ingress and the configured certificate resolver we configured with k3d.


## Deploy sshkube
This is a mechanism I (Daniel J. B. Clarke) came up with that facilitates access to a kubernetes cluster. The gist of it is that it works by tunneling kubernetes requests through an ssh endpoint which is accessed through an ssl socket. Additionally we store per-user kubernetes configurations on that intermediary ssh server, which runs on the kubernetes cluster itself.

```bash
git clone https://github.com/u8sand/sshkube.git
DOMAIN=ssh.k8s.dev.maayanlab.cloud
helm upgrade --create-namespace -n sshkube sshkube ./charts/sshkube/ -f - << EOF
ingress:
  type: traefik
  domain: ${DOMAIN}
  certResolver: default
storage:
  class: local-path

# all github users which should have access go here
githubUsers: |
  u8sand
EOF
```
