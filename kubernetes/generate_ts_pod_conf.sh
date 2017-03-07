#!/bin/bash

set -xe

if [ -z ${IAM_BASE_URL+x} ]; then
	echo "Environment variables IAM_BASE_URL is mandatory"
	exit 1
fi

DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-"cloud-vm128.cloud.cnaf.infn.it"}
REMOTE_URL=${REMOTE_URL:-"http://selenium-hub.default.svc.cluster.local:4444/wd/hub"}
TESTSUITE_REPO=${TESTSUITE_REPO:-"https://github.com/indigo-iam/iam-robot-testsuite.git"}
BRANCH=${BRANCH:-"master"}
BROWSER=${BROWSER:-"firefox"}
TIMEOUT=${TIMEOUT:-10}
POD_NAME=${POD_NAME:-"iam-testsuite"}
OUTPUT_REPORTS=${OUTPUT_REPORTS:-"reports/"}
TESTSUITE_OPTS="${TESTSUITE_OPTS:-}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-password}"
CLIENT_ID="${CLIENT_ID:-client-cred}"
CLIENT_SECRET="${CLIENT_SECRET:-secret}"
TOKEN_EXCHANGE_CLIENT_ID="${TOKEN_EXCHANGE_CLIENT_ID:-token-exchange-actor}"
TOKEN_EXCHANGE_CLIENT_SECRET="${TOKEN_EXCHANGE_CLIENT_SECRET:-secret}"

echo "
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  nodeSelector:
    role: worker
  restartPolicy: Never
  volumes:
  - name: scratch-area
    persistentVolumeClaim:
      claimName: scratch-claim
  containers:
  - name: iam-testsuite
    image: $DOCKER_REGISTRY_HOST/italiangrid/iam-robot-testsuite:latest
    volumeMounts:
    - name: scratch-area
      mountPath: /srv/scratch
    env:
    - name: IAM_BASE_URL
      value: $IAM_BASE_URL
    - name: REMOTE_URL
      value: $REMOTE_URL
    - name: TESTSUITE_REPO
      value: $TESTSUITE_REPO
    - name: TESTSUITE_BRANCH
      value: $BRANCH
    - name: BROWSER
      value: $BROWSER
    - name: TIMEOUT
      value: '$TIMEOUT'
    - name: OUTPUT_REPORTS
      value: $OUTPUT_REPORTS
    - name: TESTSUITE_OPTS
      value: '${TESTSUITE_OPTS}'
    - name: ADMIN_USER
      value: ${ADMIN_USER}
    - name: ADMIN_PASSWORD
      value: ${ADMIN_PASSWORD}
    - name: CLIENT_ID
      value: ${CLIENT_ID}
    - name: CLIENT_SECRET
      value: ${CLIENT_SECRET}
    - name: TOKEN_EXCHANGE_CLIENT_ID
      value: ${TOKEN_EXCHANGE_CLIENT_ID}
    - name: TOKEN_EXCHANGE_CLIENT_SECRET
      value: ${TOKEN_EXCHANGE_CLIENT_SECRET}
  imagePullSecrets:
  - name: cloud-vm181
" > iam-testsuite.pod.yaml