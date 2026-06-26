# Rook-Ceph

Rook is a kubernetes operator of ceph, a distributed file store. Both mature and used in production.

It's rather complex but does its job well. I've tried to use it in a very simple way -- it automatically provisions and manages raw storage disks on our hard drives and is used to serve object storage via S3.

## Install
```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: rook-ceph
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rook-ceph
  namespace: kube-system
spec:
  targetNamespace: rook-ceph
  failurePolicy: reinstall
  repo: https://charts.rook.io/release
  chart: rook-ceph
  valuesContent: |-
    enableDiscoveryDaemon: true
    monitoring:
      enabled: true
    csi:
      serviceMonitor:
        enabled: true
        labels:
          release: monitoring
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ceph-csi-drivers
  namespace: kube-system
spec:
  targetNamespace: rook-ceph
  failurePolicy: reinstall
  repo: https://ceph.github.io/ceph-csi-operator
  chart: ceph-csi-drivers
  valuesContent: |-
    operatorConfig:
      namespace: rook-ceph
      driverSpecDefaults:
        imageSet:
          name: rook-csi-operator-image-set-configmap
        nodePlugin:
          priorityClassName: system-node-critical
        controllerPlugin:
          priorityClassName: system-cluster-critical
    drivers:
      rbd:
        enabled: true
        name: rook-ceph.rbd.csi.ceph.com
      cephfs:
        enabled: false
        name: rook-ceph.cephfs.csi.ceph.com
      nfs:
        enabled: false
        name: rook-ceph.nfs.csi.ceph.com
      nvmeof:
        enabled: false
        name: rook-ceph.nvmeof.csi.ceph.com
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rook-ceph-cluster
  namespace: kube-system
spec:
  targetNamespace: rook-ceph
  failurePolicy: reinstall
  repo: https://charts.rook.io/release
  chart: rook-ceph-cluster
  valuesContent: |-
    toolbox:
      enabled: true
    monitoring:
      enabled: true
      metricsDisabled: false
      createPrometheusRules: true
      prometheusRule:
        labels:
          release: monitoring
    cephClusterSpec:
      dashboard:
        enabled: true
        ssl: false
      storage:
        useAllNodes: true
        useAllDevices: true
    cephBlockPools:
    - name: ceph-blockpool
      spec:
        failureDomain: host
        replicated:
          size: 3
        enableRBDStats: true
      storageClass:
        enabled: true
        name: ceph-block
        annotations: {}
        labels: {}
        isDefault: false
        reclaimPolicy: Delete
        allowVolumeExpansion: true
        volumeBindingMode: "Immediate"
        mountOptions: []
        parameters:
          imageFormat: "2"
          imageFeatures: layering
          csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
          csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
          csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
          csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
          csi.storage.k8s.io/controller-publish-secret-name: rook-csi-rbd-provisioner
          csi.storage.k8s.io/controller-publish-secret-namespace: rook-ceph
          csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
          csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
          csi.storage.k8s.io/fstype: ext4
    - name: ceph-blockpool-no-replicas
      spec:
        failureDomain: host
        replicated:
          size: 1
          requireSafeReplicaSize: false
        #enableRBDStats: true
      storageClass:
        enabled: true
        name: ceph-block-no-replicas
        annotations: {}
        labels: {}
        isDefault: true
        reclaimPolicy: Delete
        allowVolumeExpansion: true
        volumeBindingMode: "Immediate"
        mountOptions: []
        parameters:
          imageFormat: "2"
          imageFeatures: layering
          csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
          csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
          csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
          csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
          csi.storage.k8s.io/controller-publish-secret-name: rook-csi-rbd-provisioner
          csi.storage.k8s.io/controller-publish-secret-namespace: rook-ceph
          csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
          csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
          csi.storage.k8s.io/fstype: ext4
    cephFileSystems: []
    cephObjectStores:
    - name: ceph-objectstore
      spec:
        metadataPool:
          failureDomain: host
          replicated:
            size: 3
        dataPool:
          failureDomain: host
          erasureCoded:
            dataChunks: 2
            codingChunks: 1
          parameters:
            bulk: "true"
        preservePoolsOnDelete: true
        gateway:
          service:
            annotations:
              maayanlab.cloud/ingress: https://s3.k8s.maayanlab.cloud
              traefik.ingress.kubernetes.io/responseforwarding-flushinterval: -1
          port: 80
          resources:
            limits:
              memory: "2Gi"
            requests:
              cpu: "1000m"
              memory: "1Gi"
          instances: 1
          priorityClassName: system-cluster-critical
      storageClass:
        enabled: true
        name: ceph-bucket
        reclaimPolicy: Delete
        volumeBindingMode: "Immediate"
        annotations: {}
        labels: {}
        parameters:
          region: us-east-1
      ingress:
        enabled: false
      route:
        enabled: false
EOF
```

## Access Dashboard
```bash
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

kubectl port-forward svc/rook-ceph-mgr-dashboard -n rook-ceph 7000

# dashboard is then available at http://localhost:7000
```

## Access Toolbox
```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```

## Configure S3 Access
```bash
kubectl apply -f - << EOF
apiVersion: ceph.rook.io/v1
kind: CephObjectStoreUser
metadata:
  name: admin
  namespace: rook-ceph
spec:
  store: ceph-objectstore
  displayName: "Administrator"
EOF

kubectl -n rook-ceph get secret rook-ceph-object-user-ceph-objectstore-admin -o jsonpath='{.data.AccessKey}' | base64 --decode
kubectl -n rook-ceph get secret rook-ceph-object-user-ceph-objectstore-admin -o jsonpath='{.data.SecretKey}' | base64 --decode

```

### rclone config
```
[rook-ceph]
type = s3
provider = Ceph
access_key_id = <TODO>
secret_access_key = <TODO>
endpoint = https://s3.k8s.maayanlab.cloud
```

## Create Bucket
```bash
# create the actual bucket
rclone mkdir rook-ceph:test

# configure the bucket's default policy
cat > policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AnonymousReadAccess",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}",
                "arn:aws:s3:::${BUCKET}/*"
            ]
        }
    ]
}
EOF
AWS_ACCESS_KEY_ID=<TODO> AWS_SECRET_ACCESS_KEY=<TODO> aws --endpoint-url=https://s3.k8s.maayanlab.cloud s3api put-bucket-policy --bucket ${BUCKET} --policy file://policy.json

```


## Monitoring
To get monitoring working I had to do the following:
```bash
curl -s "https://raw.githubusercontent.com/rook/rook/master/deploy/examples/monitoring/grafana/Ceph%20Cluster%20Dashboard.json" -o ceph-cluster.json
curl -s "https://raw.githubusercontent.com/rook/rook/master/deploy/examples/monitoring/grafana/Ceph%20OSD%20Single%20Dashboard.json" -o ceph-osd.json
curl -s "https://raw.githubusercontent.com/rook/rook/master/deploy/examples/monitoring/grafana/Ceph%20Pools%20Dashboard.json" -o ceph-pools.json
kubectl create configmap graphana-dashobard-ceph-cluster  -n monitoring --from-file=ceph-cluster.json=ceph-cluster.json --from-file=ceph-osd.json=ceph-osd.json --from-file=ceph-pools.json=ceph-pools.json
kubectl label -n monitoring configmap/graphana-dashobard-ceph-cluster grafana_dashboard=1
```

Then it's available on grafana (see [grafana dashboard access instructions](./70-prometheus.md)). I've yet to get it working on the ceph dashboard.


## Recovery

### Un-deleting an accidently deleted Ceph CRD

At one point i saw CephCluster was in phase "Deleting" -- i certainly didn't delete it, maybe a failed Helm upgrade did so. In anycase it will refuse to delete since multiple things depend on it (which is great). The same thing happend to the CephObjectStore. I was able to fix both with:

The rook krew "restore-deleted" command <https://github.com/rook/kubectl-rook-ceph>
