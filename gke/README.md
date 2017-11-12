# GKE install

## prerequisite

Account with billing activated, and a dedicated project. In this tutorial the project name is prometheus-demo-185320

Install gcloud: https://cloud.google.com/sdk/docs/quickstart-linux

Log to the project, run:
```
  $ gcloud auth login
```
to obtain new credentials, or if you have already logged in with a
different account:
```
  $ gcloud config set account ACCOUNT
```
to select an already authenticated account to use.

For simplicity set your projet:
```
  gcloud config set project prometheus-demo-185320

```
## create the cluster

You can do it with the UI or in the using gcloud command line:

```
gcloud beta container --project "prometheus-demo-185320" clusters create "cluster-1" --zone "us-central1-a" --username="admin" --cluster-version "1.8.2-gke.0" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --network "default" --enable-cloud-logging --no-enable-cloud-monitoring --subnetwork "default" --enable-legacy-authorization
```

get the Kubernetes cluster configuration

```
KUBECONFIG=/home/david/.kube/gce.conf gcloud container clusters get-credentials cluster-1 --zone us-central1-a --project prometheus-demo-185320
```

If you plan to work in a multi-context environment then check the project **https://github.com/dbenque/k8s-ps1** use **kcontext.sh**
```
export KUBECONFIG=$KUBECONFIG:~/.kube/gce.conf
kubectl config getcontexts
kubectl config rename-context gke_prometheus-demo-185320_us-central1-a_cluster-1 gke
```

For later use get the External_IP of one node:
```
gcloud compute instances list --project prometheus-demo-185320

IP=35.188.62.95
```

# install the application

```
kubectl run resto --image=dbenque/prom-demo-resto:v2 --expose --port=8080
```

Note: I am not using ngnix ingress because the I am facing problem with content-type overwrite that prevent correct loading of css and js resources that are sent as "text/html"

Move the service **resto** as node port doing edit (change ClusterIP to NodePort):
```
kk edit service resto
```
then retrieve the allocated NodePort
```
PORTRESTO=$(kk get service resto -ojsonpath='{..nodePort}')
```
Open firewall
```
gcloud compute firewall-rules create resto --allow tcp:$PORTRESTO
```

Now browse http://IP:PORTRESTO

