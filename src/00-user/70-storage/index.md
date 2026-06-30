# Storage Classes Available on Cluster

```
volumes:
  yourapp-postgres-data:
    x-kubernetes:
      size: 1Gi
      class: >>>local-path<<<
```

The "class" here can be one of the following:

- `rclone-ceph-s3-kube-csi`
  - arbitrary storage backed by S3 served by Ceph: fast reads, expensive writes, safe from storage failure. "atomic" read/writes only
- `rclone-aws-s3-k8s-maayanlab-cloud`
  - storage backed by S3 served by AWS: fast reads, fast writes, independent of local cluster. "atomic" read/writes only. costs money generally avoid
- `rclone-csi-s3-k8s-public`
  - access our public S3 buckets on Ceph, readonly
- `ceph-block`
  - redundant block storage: fast reads, expensive writes, safe from storage failure -- prefer `rclone-ceph-s3-kube-csi`
- `ceph-block-no-replicas`
  - non-redundant block storage: reading/writing to raw disks on cluster, NOT safe from storage failure.
- `local-path`
  - non-redundant storage: faster reading/writing to directory on root file system of cluster nodes, NOT safe from node failure -- prefer `ceph-block-no-replicas`

Generally, the size is irrelevant for S3-backed storage but relevant for block storage.