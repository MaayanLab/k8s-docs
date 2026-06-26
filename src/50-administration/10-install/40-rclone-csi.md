# RClone CSI

The RClone CSI (Container Storage Interface) allows establishing kubernetes persistent volumes backed by an rclone mount. RClone supports a wide range of cloud providers but we're mainly setting it up to utilize S3.

Using an rclone mount as a backing volume works but should be avoided generally, delays in file updates and overhead make this not suitable for something like a database or non-atomic file access.

The CSI itself allows creating persistent volumes and storage classes using the provisioner `rclone.csi.veloxpack.io` which can be configured with rclone config settings.

### Install
```bash
# NOTE: using helmchart would have been great but the DMZ doesn't permit access to github at the moment
helm template oci://ghcr.io/veloxpack/charts/csi-driver-rclone -n kube-system  | kubectl apply -f -
```

### Default storage class
```bash
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rclone-csi-s3-k8s-public
provisioner: rclone.csi.veloxpack.io
parameters:
  remote: "s3"
  remotePath: "\${pvc.metadata.name}"
  configData: |
    [s3]
    type = s3
    provider = Ceph
    endpoint = https://s3.k8s.maayanlab.cloud
    env_auth = false
    access_key_id =
    secret_access_key =
mountOptions:
  - allow-other
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF
```
