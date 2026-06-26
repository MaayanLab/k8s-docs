# Kubernetes Auto Ingress

This was made by us to make the vast majority of apps simpler to expose via an ingress through an annotation on the deployment or service of the form:

`maayanlab.cloud/ingress: https://yourdomain.com/maybe_prefix`

The service (if necessary), and the ingress will then be created and managed automatically.

```bash
kubectl apply -f - << EOF
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: kubernetes-auto-ingress
  namespace: kube-system
spec:
  repo: https://maayanlab.github.io/helm-charts
  chart: kubernetes-auto-ingress
  version: 0.3.2
  failurePolicy: reinstall
  valuesContent: |-
    annotationKey: maayanlab.cloud/ingress
    extraAnnotations:
      http:
        ingress:
          nginx.ingress.kubernetes.io/ssl-redirect: "false"
          traefik.ingress.kubernetes.io/router.tls.certresolver: null
      https:
        ingress:
          traefik.ingress.kubernetes.io/router.entrypoints: websecure
          traefik.ingress.kubernetes.io/router.tls.certresolver: default
    ingressClassName: traefik
    ingressCreateTLS: false
    rbac:
      create: true
    serviceAccount:
      create: true
    watchNamespace: '*'
EOF
```
