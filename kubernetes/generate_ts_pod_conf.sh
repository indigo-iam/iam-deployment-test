#!/bin/bash

set -xe

if [ -z ${IAM_BASE_URL+x} ]; then
	echo "Environment variables IAM_BASE_URL is mandatory"
	exit 1
fi

IAM_TEST_CLIENT_URL=${IAM_TEST_CLIENT_URL:-"$IAM_BASE_URL/iam-test-client"}
DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-"cloud-vm114.cloud.cnaf.infn.it"}
REMOTE_URL=${REMOTE_URL:-"http://selenium-hub.default.svc.cluster.local:4444/wd/hub"}
TESTSUITE_REPO=${TESTSUITE_REPO:-"https://github.com/indigo-iam/iam-robot-testsuite.git"}
TESTSUITE_BRANCH=${TESTSUITE_BRANCH:-"master"}
BROWSER=${BROWSER:-"firefox"}
TIMEOUT=${TIMEOUT:-10}
POD_NAME=${POD_NAME:-"iam-testsuite"}
OUTPUT_REPORTS=${OUTPUT_REPORTS:-"reports/"}
TESTSUITE_OPTS="${TESTSUITE_OPTS:-}"
NAMESPACE=${NAMESPACE:-"default"}
IAM_HTTP_SCHEME=${IAM_HTTP_SCHEME:-"https"}
IAM_HTTP_HOST=${IAM_HTTP_HOST:-"iam-deploy-test.default.svc.cluster.local"}

echo "
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
spec:
  nodeSelector:
    role: worker
  restartPolicy: Never
  volumes:
  - name: scratch-area
    nfs:
      server: 10.0.0.30
      path: /srv/kubernetes/volumes/scratch
  containers:
  - name: iam-testsuite
    image: $DOCKER_REGISTRY_HOST/italiangrid/iam-robot-testsuite:latest
    volumeMounts:
    - name: scratch-area
      mountPath: /srv/scratch
    env:
    - name: IAM_BASE_URL
      value: $IAM_BASE_URL
    - name: IAM_HTTP_SCHEME
      value: ${IAM_HTTP_SCHEME}
    - name: IAM_HTTP_HOST
      value: ${IAM_HTTP_HOST}
    - name: IAM_TEST_CLIENT_URL
      value: $IAM_TEST_CLIENT_URL
    - name: REMOTE_URL
      value: $REMOTE_URL
    - name: TESTSUITE_REPO
      value: $TESTSUITE_REPO
    - name: TESTSUITE_BRANCH
      value: $TESTSUITE_BRANCH
    - name: BROWSER
      value: $BROWSER
    - name: TIMEOUT
      value: '$TIMEOUT'
    - name: OUTPUT_REPORTS
      value: $OUTPUT_REPORTS
    - name: TESTSUITE_OPTS
      value: '$TESTSUITE_OPTS'
    - name: ADMIN_USER
      valueFrom:
        configMapKeyRef:
          name: iam-ts-config
          key: admin_user
    - name: ADMIN_PASSWORD
      valueFrom:
        configMapKeyRef:
          name: iam-ts-config
          key: admin_password
    - name: CLIENT_ID
      valueFrom:
        configMapKeyRef:
          name: iam-ts-config
          key: client_id
    - name: CLIENT_SECRET
      valueFrom:
        configMapKeyRef:
          name: iam-ts-config
          key: client_secret
    - name: TOKEN_EXCHANGE_CLIENT_ID
      valueFrom:
        configMapKeyRef:
          name: iam-ts-config
          key: token_exchange_client_id
    - name: TOKEN_EXCHANGE_CLIENT_SECRET
      valueFrom:
        configMapKeyRef:
          name: iam-ts-config
          key: token_exchange_client_secret
" > iam-testsuite.pod.yaml