## LiteLLM Reverse Proxy

Since our GPU machine at sinai can access the DMZ directly..

```bash
# NOTE: <DMZHOST> -> 146.203.151.179

# configure GatewayPorts clientspecified in <DMZHOST>'s /etc/ssh/sshd_config

# reverse tunnel, 0.0.0.0:4000 will serve what we have running at localhost:4000 (which is LiteLLM)
#[maayanlab-gpu-sys0]$ commands run here
ssh -NR 0.0.0.0:4000:localhost:4000 <DMZHOST>

# create service as alias to the port on <DMZHOST> in default namespace
kubectl apply -n default -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: litellm
  annotations:
    service.kubernetes.io/topology-mode: external
spec:
  ports:
  - name: http
    port: 80
    targetPort: 4000
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: litellm
  labels:
    kubernetes.io/service-name: litellm
addressType: IPv4
ports:
  - name: http
    port: 4000
endpoints:
  - addresses:
      - "<TODO>"
EOF

#  verify that it's accessible within in the cluster
kubectl run shell --image=alpine --rm -it -- /bin/sh
apk add --no-cache curl
curl http://litellm.default.svc.cluster.local/v1/models
```
