#!/bin/bash

set -xe

if [ -z ${BRANCH+x} ] || [ -z ${BROWSER+x} ] || [ -z ${DOCKER_REGISTRY_HOST+x} ]; then
	echo "Environment variables BRANCH, BROWSER, DOCKER_REGISTRY_HOST are mandatory"
	exit 1
fi

for file in *.sed; do
	newfile=`basename -s .sed ${file}`
	envsubst < ${file} > ${newfile}
done
