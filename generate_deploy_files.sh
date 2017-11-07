#!/bin/bash

set -xe

if [ -z ${BROWSER+x} ] || [ -z ${DOCKER_REGISTRY_HOST+x} ] || [ -z ${IAM_IMAGE+x} ]; then
	echo "Environment variables BROWSER, DOCKER_REGISTRY_HOST, IAM_IMAGE are mandatory"
	exit 1
fi

for file in `find kubernetes/ -type f -name *.tmpl`; do
	newfile=`basename -s .tmpl ${file}`
	envsubst < ${file} > kubernetes/${newfile}
done
