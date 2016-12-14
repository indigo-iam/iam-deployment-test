#!/bin/bash

set -xe

if [ -z ${BRANCH+x} ] || [ -z ${DOCKER_REGISTRY_HOST+x} ]; then
	echo "Environment variables BRANCH and DOCKER_REGISTRY_HOST are mandatory"
	exit 1
fi

for file in *.sed; do
	newfile=`basename -s .sed $file`
	cat $file | sed "s/\$BRANCH/$BRANCH/g;s/\$DOCKER_REGISTRY_HOST/$DOCKER_REGISTRY_HOST/g" > $newfile
done
