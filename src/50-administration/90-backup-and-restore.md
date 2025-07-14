# Backup and Restoration

Not yet set up but planned are:
- volume backups
  - restic backups
- kubernetes dumps
  - basically just `kubectl get $TYPE -n $NAMESPACE -oyaml > $TIMESTAMP/$NAMESPACE/$TYPE/$NAME.yaml` for everything
  - restore easily with `kubectl apply -f < $TIMESTAMP/$NAMESPACE/$TYPE/$NAME.yaml`
