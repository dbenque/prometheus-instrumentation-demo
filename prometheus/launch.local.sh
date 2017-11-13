#!/bin/bash

BASEDIR=$(dirname "$0")

docker stop prom-local
docker stop prom-fed
docker stop prom-nodeexporter
sleep 2

chmod +755 local.prometheus.yml
chmod +755 federation.prometheus.yml

docker run -d --name=prom-local --net=host -v $PWD/local.prometheus.yml:/etc/prometheus/prometheus.yml --rm prom/prometheus
docker run --name=prom-fed --net=host -v $PWD/federation.prometheus.yml:/etc/prometheus/prometheus.yml --rm prom/prometheus --web.listen-address=:9091 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles 
docker run -d --name=prom-nodeexporter --net="host" --pid="host" --rm prom/node-exporter