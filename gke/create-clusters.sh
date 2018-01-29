#!/bin/bash
## Create 2 identical GKE Clusters under the same project, install prometheus+grafana using coreos operator
# 
# PREREQUISIT: First log-in and set project
# gcloud auth login
# gcloud config set project prometheus-demo-185320    <-- replace with your own project
#
# Caution: The following files will be removed by the script:
# ~/.kube/gce[0-9].conf

gke_cluster()
{
    NUMCLUSTER=$1
    NBNODE=$2

    gcloud beta container --project "prometheus-demo-185320" clusters create "cluster-$NUMCLUSTER" --zone "us-central1-a" --username="admin" --cluster-version "1.8.6-gke.0" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "$NBNODE" --network "default" --enable-cloud-logging --no-enable-cloud-monitoring --subnetwork "default" --enable-legacy-authorization
    rm $HOME/.kube/gce$NUMCLUSTER.conf
    KUBECONFIG=$HOME/.kube/gce$NUMCLUSTER.conf gcloud container clusters get-credentials cluster-$NUMCLUSTER --zone us-central1-a --project prometheus-demo-185320
    KUBECONFIG=~/.kube/gce$NUMCLUSTER.conf
    kubectl config get-contexts
    kubectl config rename-context gke_prometheus-demo-185320_us-central1-a_cluster-$NUMCLUSTER gke$NUMCLUSTER
    kubectl config use-context gke$NUMCLUSTER

    MYUSER=$(gcloud info | grep Account | sed -rn 's/.*\[(.*)\]$/\1/p')
    kubectl create clusterrolebinding myname-cluster-admin-binding --clusterrole=cluster-admin --user=$MYUSER

    kubectl create -f $GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/resto/artifacts
    PORTRESTO=$(kubectl get service resto -ojsonpath='{..nodePort}')
    gcloud compute firewall-rules delete resto$NUMCLUSTER --quiet 2> /dev/null
    gcloud compute firewall-rules create resto$NUMCLUSTER --allow tcp:$PORTRESTO

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
    kubectl apply -f <(cat $KUBEPROM/manifests/prometheus/prometheus-k8s.yaml; echo "  externalLabels:"; echo "    cluster: gke$NUMCLUSTER")
    kubectl apply -f $KUBEPROM/manifests/prometheus/prometheus-k8s-service-monitor-kubelet.yaml

    PORT_PROM=$(kubectl get service prometheus-k8s -ojsonpath='{..nodePort}')
    PORT_GRAFANA=$(kubectl get service grafana -ojsonpath='{..nodePort}')
    PORT_ALERT=$(kubectl get service alertmanager-main -ojsonpath='{..nodePort}')

    gcloud compute firewall-rules delete monitoring$NUMCLUSTER --quiet 2> /dev/null
    gcloud compute firewall-rules create monitoring$NUMCLUSTER --allow tcp:$PORT_PROM,tcp:$PORT_GRAFANA,tcp:$PORT_ALERT

    kubectl create --namespace=$NAMESPACE -f $GOPATH/src/github.com/dbenque/prometheus-instrumentation-demo/prometheus/artifacts
}

#Create cluster-1 with 3 nodes
gke_cluster 1 3

#Create cluster-2 with 3 nodes
gke_cluster 2 3