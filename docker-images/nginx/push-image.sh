#!/bin/bash

set -xe

DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-"cloud-vm114.cloud.cnaf.infn.it"}

docker tag italiangrid/iam-nginx:latest ${DOCKER_REGISTRY_HOST}/italiangrid/iam-nginx:latest
docker push ${DOCKER_REGISTRY_HOST}/italiangrid/iam-nginx:latest