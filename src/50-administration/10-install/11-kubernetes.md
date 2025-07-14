## Install Kubernetes

Kubernetes can be installed through a number of cloud providers.

It can also be installed locally with [k3s](https://github.com/k3s-io/k3s) or even simpler with [k3d](https://k3d.io/stable/) which deploys k3s with Docker.

## K3D Install
Create the k3d configuration file: `config.yaml`.
```yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: maayanlab
servers: 1
agents: 1
volumes:
# a persistent volume we set up
- volume: /export/volgrp01/:/var/lib/rancher/k3s/storage
  nodeFilters:
  - all
ports:
  - port: 443:443
    nodeFilters:
    - loadbalancer
```

Then k3d is started with
```bash
k3d cluster create --config=config.yaml
```
