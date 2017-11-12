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
kubectl create -f $GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/resto/artifacts
```

Note: I am not using ngnix ingress because the I am facing problem with content-type overwrite that prevent correct loading of css and js resources that are sent as "text/html"

Retrieve the allocated NodePort
```
PORTRESTO=$(kubectl get service resto -ojsonpath='{..nodePort}')
```
Open firewall
```
gcloud compute firewall-rules create resto --allow tcp:$PORTRESTO
```

Now browse http://IP:PORTRESTO

# install prometheus (and grafana and node exporter)

We are going to use prometheus-operator. Commands are adapted from $GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/vendor/github.com/coreos/prometheus-operator/contrib/kube-prometheus/hack/cluster-monitoring/deploy

```
NAMESPACE=monitoring
kubectl create namespace $NAMESPACE
kubectl config set-context $(kubectl config current-context) --namespace=$NAMESPACE

KUBEPROM=$GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/vendor/github.com/coreos/prometheus-operator/contrib/kube-prometheus

kubectl apply -f $KUBEPROM/manifests/prometheus-operator

# Wait for CRDs to be ready.
until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kubectl get customresourcedefinitions prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kubectl get customresourcedefinitions alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kubectl get servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kubectl get prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kubectl get alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done

kubectl apply -f $KUBEPROM/manifests/node-exporter
kubectl apply -f $KUBEPROM/manifests/kube-state-metrics
kubectl apply -f $KUBEPROM/manifests/grafana/grafana-credentials.yaml
kubectl apply -f $KUBEPROM/manifests/grafana
#find $KUBEPROM/manifests/prometheus -type f ! -name prometheus-k8s-roles.yaml ! -name prometheus-k8s-role-bindings.yaml -exec kubectl --namespace "$NAMESPACE" apply -f {} \;
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-roles.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-role-bindings.yaml
kubectl apply -f $KUBEPROM/manifests/alertmanager/

kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kube-scheduler.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kube-state-metrics.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-rules.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-node-exporter.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-account.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-prometheus-operator.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-alertmanager.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-prometheus.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-apiserver.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service.yaml
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kube-controller-manager.yaml
kubectl apply -f <(cat $KUBEPROM/manifests/prometheus/prometheus-k8s.yaml; echo "  externalLabels:"; echo "    cluster: gke")
kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kubelet.yaml

```

Let's create firewall rule for grafana and prometheus services
```
PORT_PROM=$(kubectl get service prometheus-k8s -ojsonpath='{..nodePort}')
PORT_GRAFANA=$(kubectl get service grafana -ojsonpath='{..nodePort}')
PORT_ALERT=$(kubectl get service alertmanager-main -ojsonpath='{..nodePort}')

gcloud compute firewall-rules create monitoring --allow tcp:$PORT_PROM,tcp:$PORT_GRAFANA,tcp:$PORT_ALERT
```

# install application monitoring

```
NAMESPACE=monitoring
kubectl create --namespace=$NAMESPACE -f $GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/prometheus/artifacts
```
