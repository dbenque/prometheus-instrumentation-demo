# create cluster with kubernetes

Doc : https://www.alibabacloud.com/help/doc-detail/53752.htm

https://ros.console.aliyun.com/

--> go to sample template and select the kubernetes sample (HA or TEST)

--> select a region. Note: You can only use ROS templates to deploy Kubernetes clusters in US West 1, China North 2, Asia Pacific SE 1, China East 1, China East 2, China South 1 and Hong Kong regions.

--> Select number of instances and types (doc here https://www.alibabacloud.com/help/faq-detail/43207.htm):  for example 2 nodes ecs.n2.medium

# Export kubeconfig using nc

On the kubernetes master node ( 47.91.156.77 in this example )

install netcat
```
yum install nc
```

then netcat the configuration
```
cat /etc/kubernetes/kube.conf | nc -l -p 40000
```

On the remote machine

```
IP=47.91.156.77; nc $IP 40000 | sed -e "s/1.1.1.1/$IP/g" | sed -e "s/kubernetes-admin@kubernetes/alibaba/g" -e "s/kubernetes-admin/alibaba/g" -e "s/kubernetes/alibaba/g" > ~/.kube/alibaba.conf

```

If you plan to work in a multi-context environment then check the project **https://github.com/dbenque/k8s-ps1** use **kcontext.sh**
```
export KUBECONFIG=$KUBECONFIG:~/.kube/alibaba.conf
kubectl config use-context alibaba
```

The insecure option must be use to skip certifiacte validation. If you are using multi-context you should remove the **--kubeconfig** option

```
alias kk='kubectl --kubeconfig=$HOME/.kube/alibaba.conf --insecure-skip-tls-verify'
```

Try to check
```
kk get pods --all-namespaces
```

# install the application

```
kk run resto --image=dbenque/prom-demo-resto:v3 --expose --port=8080
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

Now browse http://IP:PORTRESTO

# install prometheus (and grafana and node exporter)

We are going to use prometheus-operator. Commands are adapted from $GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/vendor/github.com/coreos/prometheus-operator/contrib/kube-prometheus/hack/cluster-monitoring/deploy

```
NAMESPACE=monitoring
kk create namespace $NAMESPACE
kk config set-context $(kubectl config current-context) --namespace=$NAMESPACE

KUBEPROM=$GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/vendor/github.com/coreos/prometheus-operator/contrib/kube-prometheus

kk apply -f $KUBEPROM/manifests/prometheus-operator

# Wait for CRDs to be ready.
until kk get customresourcedefinitions servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kk get customresourcedefinitions prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kk get customresourcedefinitions alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kk get servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kk get prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kk get alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done

kk apply -f $KUBEPROM/manifests/node-exporter
kk apply -f $KUBEPROM/manifests/kube-state-metrics
kk apply -f $KUBEPROM/manifests/grafana/grafana-credentials.yaml
kk apply -f $KUBEPROM/manifests/grafana
#find $KUBEPROM/manifests/prometheus -type f ! -name prometheus-k8s-roles.yaml ! -name prometheus-k8s-role-bindings.yaml -exec kk --namespace "$NAMESPACE" apply -f {} \;
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-roles.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-role-bindings.yaml
kk apply -f $KUBEPROM/manifests/alertmanager/

kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kube-scheduler.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kube-state-metrics.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-rules.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-node-exporter.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-account.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-prometheus-operator.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-alertmanager.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-prometheus.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-apiserver.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service.yaml
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kube-controller-manager.yaml
kk apply -f <(cat $KUBEPROM/manifests/prometheus/prometheus-k8s.yaml; echo "  externalLabels:"; echo "    cluster: alibaba")
kk apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kubelet.yaml

```
