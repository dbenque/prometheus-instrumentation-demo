#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR
./stop.local.sh

sleep 2

chmod +755 local.prometheus.yml

echo -e "\e[1;33mLaunching prometheus local\e[0m"
docker run -d --name=prom-local --net=host -v $PWD/local.prometheus.yml:/etc/prometheus/prometheus.yml --rm prom/prometheus
echo -e "\e[1;33mLaunching prometheus node exporter\e[0m"
docker run -d --name=prom-nodeexporter --net="host" --pid="host" --rm prom/node-exporter
echo -e "\e[1;33mLaunching grafana\e[0m"
#docker run -d --name=grafana --net=host -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" --rm grafana/grafana
docker run -d --name=grafana --net=host --rm grafana/grafana

until $(curl --output /dev/null --silent --head --fail http://admin:admin@localhost:3000/api/datasources); do
    printf '.'
    sleep 2
done
echo
echo -e "\e[1;33mAdding prometheus as datasource for Grafana\e[0m"
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"name":"prometheus","isDefault":true,"type":"prometheus","url":"http://localhost:9090","access":"proxy","jsonData":{"tlsSkipVerify":true,"timeInterval":"5s"},"secureJsonFields":{}}'  http://admin:admin@localhost:3000/api/datasources 
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"name":"promfederation","isDefault":false,"type":"prometheus","url":"http://localhost:9091","access":"proxy","jsonData":{"tlsSkipVerify":true,"timeInterval":"5s"},"secureJsonFields":{}}'  http://admin:admin@localhost:3000/api/datasources 
echo
echo -e "\e[1;33mCreating Resto Dashboard\e[0m"
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d@dash.resto.json http://admin:admin@localhost:3000/api/dashboards/db
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d@dash.fed.resto.json http://admin:admin@localhost:3000/api/dashboards/db
echo
echo -e "\e[1;33mCreating Nodes Dashboard\e[0m"
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d@dash.nodes.json http://admin:admin@localhost:3000/api/dashboards/db
echo
cd - &>/dev/null