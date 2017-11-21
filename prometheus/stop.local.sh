#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR
echo -e "\e[1;33mCleaning previous Prometheus and Grafana local installation\e[0m"
docker stop prom-local &>/dev/null
#docker stop prom-fed &>/dev/null
docker stop prom-nodeexporter &>/dev/null
docker stop grafana &>/dev/null
docker rm prom-local &>/dev/null
#docker rm prom-fed &>/dev/null
docker rm prom-nodeexporter &>/dev/null
docker rm grafana &>/dev/null

cd - &>/dev/null