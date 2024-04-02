# mssql-kubernetes-auto-fail-handler
Golang-based SQL Server Always On Availability Group Failover and Failback Handler in Kubernetes.



https://github.com/mohammadfalahat/mssql-kubernetes-auto-fail-handler/assets/7458874/a1b34893-a288-43a6-94db-b9f2fee80805


# Installation:
### Apply Kubernetes needles:

```
kubectl apply -f namespace.yml -f rbac.yml -f secrets.yml -f services.yml -f pvc.yml -f configmap.yml
kubectl apply -f 1deployment.yml -f 2deployment.yml -f 3deployment.yml
```
### Install Availability Group on Instance1 as first primary node:
Login to instance1 and run `01 - install ag and config it.sql` as a query in it.
### Copy Certificate of AG to other instances
Run content of `02 - copy certificate from primary to secondaries.sh` inside your bash or powershell.
### Join other instances as Secondary instances
Login to instance2 and instance3 and run `03 - mssql-secondary 1 and 2 sql for add secondaries.sql` as a query in them.
