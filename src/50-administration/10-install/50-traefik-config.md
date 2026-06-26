# Configure Traefik

Given that rclone-csi storageclass is configured, we can configure traefik to store LetsEncrypt TLS certificates in S3.
This lets us automatically obtain and renew certificates for https.

```bash
kubectl apply -f - << EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    hostNetwork: true
    additionalArguments:
      - "--certificatesresolvers.default.acme.email=<TODO>"
      - "--certificatesresolvers.default.acme.storage=/data/acme.json"
      - "--certificatesresolvers.default.acme.tlschallenge=true"
      - "--entryPoints.websecure.transport.respondingTimeouts.readTimeout=3600s"
      - "--entryPoints.websecure.transport.respondingTimeouts.writeTimeout=3600s"
      - "--entryPoints.websecure.transport.respondingTimeouts.idleTimeout=3600s"
    persistence:
      enabled: true
      name: data
      accessMode: ReadWriteOnce
      size: 256Mi
      storageClass: rclone-aws-s3-k8s-maayanlab-cloud
    podSecurityContext:
      runAsGroup: 65532
      runAsNonRoot: true
      runAsUser: 65532
      fsGroup: 65532
      fsGroupChangePolicy: "OnRootMismatch"
    nodeSelector:
      ingress: "true"
---
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: default
  namespace: kube-system
spec:
  minVersion: VersionTLS12
  sniStrict: true
  cipherSuites:
    - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
    - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
    - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
    - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
EOF
```
