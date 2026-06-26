# rclone S3 k8s-maayanlab-cloud StorageClass

With the RClone CSI in place, here we create a StorageClass which uses a bucket in AWS S3. In the future we might store it in our locally hosted S3 server but with that in flux we'll store things in the more reliable AWS S3.

PVCs using this storageclass stores the files in the `k8s-maayanlab-cloud` bucket at `{volume-namespace}/{volume-name}`.
The secret has AWS credentials giving it full access to the bucket.

### Configure
```bash
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rclone-aws-s3-k8s-maayanlab-cloud
provisioner: rclone.csi.veloxpack.io
parameters:
  remote: "aws-s3-k8s-maayanlab-cloud"
  remotePath: "k8s-maayanlab-cloud/\${pvc.metadata.namespace}/\${pvc.metadata.name}"
  csi.storage.k8s.io/node-publish-secret-name: "rclone-aws-s3-k8s-maayanlab-cloud-secret"
  csi.storage.k8s.io/node-publish-secret-namespace: "kube-system"
  umask: "0077"
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
---
apiVersion: v1
kind: Secret
metadata:
  name: rclone-aws-s3-k8s-maayanlab-cloud-secret
  namespace: kube-system
type: Opaque
stringData:
  remote: "aws-s3-k8s-maayanlab-cloud"
  remotePath: "<TODO>/\${pvc.metadata.namespace}/\${pvc.metadata.name}"
  configData: |
    [aws-s3-k8s-maayanlab-cloud]
    type = s3
    provider = aws
    access_key_id = <TODO>
    secret_access_key = <TODO>
EOF
```
