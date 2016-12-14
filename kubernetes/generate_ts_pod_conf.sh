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
      value: $TIMEOUT
    - name: OUTPUT_REPORTS
      value: $OUTPUT_REPORTS
  imagePullSecrets:
  - name: cloud-vm181
" > iam-testsuite.pod.yaml