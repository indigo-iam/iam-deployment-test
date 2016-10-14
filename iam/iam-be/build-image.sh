#!/bin/bash

BRANCH=${BRANCH:-}

docker build --no-cache -t italiangrid/iam-login-service:$BRANCH .
