# User Administration

Users gain access to the cluster through [sshkube](https://github.com/u8sand/sshkube), installed via helm chart.

## Adding/Removing github users
To manage users, their github username can simply be added/removed from the sshkube configmap (one user per line):
```bash
sshkube run kubectl -n sshkube edit configmap/sshkube-github-users
```

Currently, sshkube prepares authentication at startup. This means that any modification to the configmap, or new ssh keys added by users require a restart to sshkube to be usable.
```bash
sshkube run kubectl -n sshkube rollout restart sshkube
```
In the future, sshkube will likely be updated to identify these things automatically.

## User access controls (ACLs)
Be default, each user is given access to a namespace corresponding to their github username. They can however be given more access with kubernetes-based access controls. Usually this means adding a clusterrolebinding to their service account (which is also their github username in their namespace).

For example, to give someone super user privileges, you would first add their username, for example, `someuser` to the configmap. Then you'd create the following clusterrolebinding:
```bash
sshkube run kubectl create clusterrolebinding someuser --clusterrole=cluster-admin --serviceaccount=someuser:someuser
```

To give them less privileges, like to another namespace, you'd craft a new clusterrole which you could subsequently bind to the user.
