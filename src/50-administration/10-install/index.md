# Installation

This part of the guide has details about how this was initially installed for reproducing it in another environment in the future.

1. [Kubernetes](./11-kubernetes.md) installation
2. Ma'ayan lab kubernetes extensions installation, in order
  1. [autoingress](./20-kuberenetes-auto-ingress.md): maayanlab.cloud/ingress annotations for ingresses
  2. [rook-ceph](./30-rook-ceph.md): distributed file system (likely not needed on single node install)
  3. rclone-csi: kubernetes mounts of s3 (or any rclone accessible cloud provider)
    1. [rclone-csi](./40-rclone-csi.md)
    2. [rclone-aws-s3-k8s-maayanlab-cloud](./41-rclone-aws-s3-k8s-maayanlab-cloud.md)
    3. [rclone-ceph-s3-kube-csi](./42-rclone-ceph-s3-kube-csi.md)
  4. [traefik-config](./50-traefik-config.md): congiure tls termination & other settings
  5. [prometheus](./70-prometheus.md): cluster monitoring (likely not needed on single node install)
  6. [sshkube](./80-sshkube.md): cluster access over ssh
  7. [litellm](./90-litellm.md): reverse proxy access to local LLM
