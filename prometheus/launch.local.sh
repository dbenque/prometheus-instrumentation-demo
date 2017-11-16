#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR
echo -e "\e[1;33mCleaning previous Prometheus and Grafana local installation\e[0m"
docker stop prom-local &>/dev/null
docker stop prom-fed &>/dev/null
docker stop prom-nodeexporter &>/dev/null
docker stop grafana &>/dev/null
docker rm prom-local &>/dev/null
docker rm prom-fed &>/dev/null
docker rm prom-nodeexporter &>/dev/null
docker rm grafana &>/dev/null

sleep 2

chmod +755 local.prometheus.yml
chmod +755 federation.prometheus.yml

echo -e "\e[1;33mLaunching prometheus local\e[0m"
docker run -d --name=prom-local --net=host -v $PWD/local.prometheus.yml:/etc/prometheus/prometheus.yml --rm prom/prometheus
echo -e "\e[1;33mLaunching prometheus federation\e[0m"
docker run -d --name=prom-fed --net=host -v $PWD/federation.prometheus.yml:/etc/prometheus/prometheus.yml --rm prom/prometheus --web.listen-address=:9091 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles 
echo -e "\e[1;33mLaunching prometheus node exporter\e[0m"
docker run -d --name=prom-nodeexporter --net="host" --pid="host" --rm prom/node-exporter
echo -e "\e[1;33mLaunching grafana\e[0m"
docker run -d --name=grafana --net=host -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" --rm grafana/grafana
cd - &>/dev/null

until $(curl --output /dev/null --silent --head --fail http://admin:admin@localhost:3000/api/datasources); do
    printf '.'
    sleep 2
done
echo
echo -e "\e[1;33mAdding prometheus as datasource for Grafana\e[0m"
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"name":"prometheus","isDefault":true,"type":"prometheus","url":"http://localhost:9090","access":"proxy","jsonData":{"tlsSkipVerify":true,"timeInterval":"5s"},"secureJsonFields":{}}'  http://admin:admin@localhost:3000/api/datasources 
echo