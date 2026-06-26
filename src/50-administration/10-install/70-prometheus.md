## Install
```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: monitoring
  namespace: kube-system
spec:
  targetNamespace: monitoring
  failurePolicy: reinstall
  repo: https://prometheus-community.github.io/helm-charts
  chart: kube-prometheus-stack
  valuesContent: |-
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: ceph-block-no-replicas
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 50Gi
EOF
```

## Access Dashboard
```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

<http://localhost:3000>

username: admin
password: from above
