#!/bin/sh

set -xe

DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-"cloud-vm128.cloud.cnaf.infn.it"}
IMAGE_NAME=${IMAGE_NAME:"italiangrid/iam-login-service"}
TAG=${TAG:-}

image=${IMAGE_NAME}:${TAG}
dest=${DOCKER_REGISTRY_HOST}/$image
	
docker tag $image $dest
docker push $dest
