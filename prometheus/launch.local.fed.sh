#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR
./stop.local.fed.sh

sleep 2

chmod +755 federation.prometheus.yml

echo -e "\e[1;33mLaunching prometheus federation\e[0m"
docker run -d --name=prom-fed --net=host -v $PWD/federation.prometheus.yml:/etc/prometheus/prometheus.yml --rm prom/prometheus --web.listen-address=:9091 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles 
echo
cd - &>/dev/null