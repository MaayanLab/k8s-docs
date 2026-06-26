# rclone Ceph S3 kube-csi StorageClass

With the RClone CSI in place, here we create a StorageClass which uses a bucket in Ceph S3.

PVCs using this storageclass stores the files in the `kube-csi` bucket at `{volume-namespace}/{volume-name}`.
The secret has ceph credentials giving it full access to the bucket.

### Configure

```bash
# prepare a bucket & credentials for this storeageclass
kubectl apply -f - << EOF
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: kube-csi
  namespace: kube-system
spec:
  bucketName: kube-csi
  storageClassName: ceph-bucket
EOF

# get the credentials
kubectl -n kube-system get secret kube-csi -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 --decode
kubectl -n kube-system get secret kube-csi -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 --decode

# create the storageclass
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rclone-ceph-s3-kube-csi
provisioner: rclone.csi.veloxpack.io
parameters:
  remote: "ceph-s3-kube-csi"
  remotePath: "kube-csi/\${pvc.metadata.namespace}/\${pvc.metadata.name}"
  csi.storage.k8s.io/node-publish-secret-name: "rclone-ceph-s3-kube-csi-secret"
  csi.storage.k8s.io/node-publish-secret-namespace: "kube-system"
  umask: "0077"
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
---
apiVersion: v1
kind: Secret
metadata:
  name: rclone-ceph-s3-kube-csi-secret
  namespace: kube-system
type: Opaque
stringData:
  remote: "ceph-s3-kube-csi"
  remotePath: "kube-csi/\${pvc.metadata.namespace}/\${pvc.metadata.name}"
  configData: |
    [ceph-s3-kube-csi]
    type = s3
    provider = ceph
    access_key_id = <TODO>
    secret_access_key = <TODO>
    endpoint = https://s3.k8s.maayanlab.cloud
EOF
```
