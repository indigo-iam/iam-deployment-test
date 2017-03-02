#!/bin/bash

set -xe

IMAGE_NAME=${IMAGE_NAME:-"italiangrid/iam-login-service"}
TAG=${TAG:-}

docker build --no-cache -t ${IMAGE_NAME}:${TAG} .
