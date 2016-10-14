#!/bin/bash

set -xe

IAM_REPO=${IAM_REPO:-https://github.com/indigo-iam/iam.git}
BRANCH=${BRANCH:-}

if [ -z $BRANCH ]; then
	echo "Error! No branch specified!"
	exit 1
fi 

builder_name=iam-builder
workdir=$PWD/..

cd $workdir/maven/
sh build-image.sh

docker run --name=$builder_name \
	-e REPO=$IAM_REPO \
	-e REPO_BRANCH=$BRANCH \
	italiangrid/iam-builder

filesdir=$workdir/iam/iam-be/files/
mkdir -p $filesdir

docker cp $builder_name:/iam/iam-login-service/target/iam-login-service.war $filesdir
docker cp $builder_name:/iam/docker/saml-idp/idp/shibboleth-idp/metadata/idp-metadata.xml $filesdir

docker rm $builder_name

cd $workdir/iam/iam-be
sh build-image.sh
sh push-image.sh