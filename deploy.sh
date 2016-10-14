#!/bin/bash

set -xe

TESTSUITE_REPO="${TESTSUITE_REPO:-https://github.com/indigo-iam/iam-robot-testsuite.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"
BROWSER="${BROWSER:-firefox}"
TIMEOUT="${TIMEOUT:-10}"
DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-"cloud-vm128.cloud.cnaf.infn.it"}

export IMAGE_TAG=$REPO_BRANCH

netname="iam_default"
ts_name=iam-ts
builder_name=iam-builder
workdir=$PWD

function cleanup(){
	retcod=$?
	if [ $retcod != 0 ]; then
		echo "Caught error! Cleanup..."
		
		cd $workdir
		docker-compose -f iam/docker-compose.yml stop
		docker-compose -f iam/docker-compose.yml rm -f
		sh iam-robot-testsuite/docker/selenium-grid/selenium_grid.sh stop
		docker rm $ts_name
		docker rm $builder_name
	fi
	exit $retcod
}

trap cleanup EXIT SIGINT SIGTERM SIGABRT


## Create more entropy
list=`docker ps -aq -f status=exited -f name=haveged | xargs`
if [ ! -z "$list"]; then
	docker rm $list
fi

id=`docker ps -q -f status=running -f name=haveged`
if [ -z "$id" ]; then
	docker run --name=haveged --privileged -d harbur/haveged
fi


## Compile and bring on IAM
set +e
docker pull $DOCKER_REGISTRY_HOST/italiangrid/iam-login-service:$IMAGE_TAG

if [ $? -ne 0 ]; then
	set -e
	cd maven/
	sh build-image.sh
	docker run --name=$builder_name \
		-e REPO=https://github.com/indigo-iam/iam.git \
		-e REPO_BRANCH=$REPO_BRANCH \
		italiangrid/iam-builder
	
	filesdir=$workdir/iam/iam-be/files/
	mkdir -p $filesdir
	
	docker cp $builder_name:/iam/iam-login-service/target/iam-login-service.war $filesdir
	docker cp $builder_name:/iam/docker/saml-idp/idp/shibboleth-idp/metadata/idp-metadata.xml $filesdir
	
	docker rm $builder_name
	
	cd $workdir/iam
	docker-compose build
fi
set -e

cd $workdir/iam
docker-compose rm -f
docker-compose up -d

cd $workdir

iam_ip=`docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' iam`


## Bring on Selenium Grid
git clone $TESTSUITE_REPO
cd iam-robot-testsuite
git checkout $REPO_BRANCH

export DOCKER_NET_NAME=$netname
export IAM_HOSTNAME="iam.local.io"

sh docker/selenium-grid/selenium_grid.sh start

cd $workdir


## Run testsuite
set +e
docker pull $DOCKER_REGISTRY_HOST/italiangrid/iam-robot-testsuite:latest
if [ $? -ne 0 ]; then
	cd iam-robot-testsuite/docker
	./build-image.sh
	docker tag italiangrid/iam-robot-testsuite $DOCKER_REGISTRY_HOST/italiangrid/iam-robot-testsuite:latest
fi

cd $workdir

docker run --net $DOCKER_NET_NAME \
	--name=$ts_name \
	--add-host $IAM_HOSTNAME:$iam_ip \
	-e TESTSUITE_REPO=$TESTSUITE_REPO \
	-e TESTSUITE_BRANCH=$REPO_BRANCH \
	-e IAM_BASE_URL=https://iam.local.io \
	-e REMOTE_URL=http://selenium-hub:4444/wd/hub \
	-e BROWSER=$BROWSER \
	-e TIMEOUT=$TIMEOUT \
	$DOCKER_REGISTRY_HOST/italiangrid/iam-robot-testsuite:latest
set -e


## Copy reports
rm -rfv $workdir/reports

reportdir=$workdir/reports

mkdir $reportdir

docker cp $ts_name:/home/tester/iam-robot-testsuite/reports $reportdir


## Stop services and cleanup
docker-compose -f iam/docker-compose.yml stop
docker-compose -f iam/docker-compose.yml rm -f
sh iam-robot-testsuite/docker/selenium-grid/selenium_grid.sh stop
docker rm $ts_name
