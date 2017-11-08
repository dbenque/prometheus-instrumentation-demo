#!/bin/bash
IMAGE=prom-demo-resto
USER=$(docker info 2> /dev/null | grep Username | cut -d' ' -f2)
REGISTRY=$(docker info 2> /dev/null | grep Registry | cut -d' ' -f2)

IMAGEFULL=$USER/$IMAGE
VERSION=$(git tag|tail -1)

if [[ $USER == "" ]]; then
    echo "No docker user signed. Please log to a registry: 'docker login'"
    exit 1
fi

if [[ $VERSION == "" ]]; then
    echo "No version defined. Please add a git tag."
    exit 1
fi

PUBLISHED=$(curl -s https://registry.hub.docker.com/v1/repositories/$IMAGEFULL/tags | jq '.[].name' | sed -e 's/"//g' | grep -E "^$VERSION\$" | wc -l)

if [[ $PUBLISHED == 1 ]]; then
    echo "Version $VERSION, already exist. Change your git tag."
    exit 1
fi

BASEDIR=$(dirname "$0")
cd $BASEDIR
make docker
docker tag $IMAGE:latest $IMAGEFULL:$VERSION
docker push $IMAGEFULL:$VERSION
cd -