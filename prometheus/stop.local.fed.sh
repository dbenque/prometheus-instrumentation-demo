#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR
echo -e "\e[1;33mCleaning previous Prometheus Federation\e[0m"
docker stop prom-fed &>/dev/null
docker rm prom-fed &>/dev/null

cd - &>/dev/null