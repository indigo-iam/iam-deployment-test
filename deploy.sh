#!/bin/bash

set -xe

TESTSUITE_REPO="${TESTSUITE_REPO:-https://github.com/indigo-iam/iam-robot-testsuite.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"
BROWSER="${BROWSER:-firefox}"

netname="iam_default"
container_name=iam-ts
workdir=$PWD

function cleanup(){
	retcod=$?
	
	echo "Caught error! Cleanup..."
	
	cd $workdir
	docker-compose -f iam/docker-compose.yml stop
	docker-compose -f iam/docker-compose.yml rm -f
	sh iam-robot-testsuite/docker/selenium-grid/selenium_grid.sh stop
	docker rm $container_name
	
	exit $retcod
}

trap cleanup ERR SIGINT SIGTERM SIGABRT


## Create more entropy
list=`docker ps -aq -f status=exited -f name=haveged | xargs`
if [ ! -z "$list"]; then
	docker rm $list
fi

id=`docker ps -q -f status=running -f name=haveged`
if [ -z "$id" ]; then
	docker run --name=haveged --privileged -d harbur/haveged
fi


## Bring on IAM

mkdir scratch/
cd scratch/

git clone https://github.com/indigo-iam/iam.git
cd iam/
git checkout $REPO_BRANCH

cd iam-persistence/
mvn clean install

cd ..
mvn clean package

filesdir=$workdir/iam/iam-be/files/
mkdir -p $filesdir

cp iam-login-service/target/iam-login-service.war $filesdir
cp docker/saml-idp/idp/shibboleth-idp/metadata/idp-metadata.xml $filesdir

cd $workdir/iam

docker-compose rm -f
docker-compose up --build -d

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


## Waiting for IAM
start_ts=$(date +%s)
timeout=300
sleeped=0

set +e
while true; do
    (echo > /dev/tcp/$iam_ip/443) >/dev/null 2>&1
    result=$?
    if [[ $result -eq 0 ]]; then
        end_ts=$(date +%s)
        echo "IAM is available after $((end_ts - start_ts)) seconds"
        break
    fi
    echo "Waiting for IAM..."
    sleep 5
    
    sleeped=$((sleeped+5))
    if [ $sleeped -ge $timeout  ]; then
    	echo "Timeout!"
    	exit 1
	fi
done
set -e


## Run testsuite
cd iam-robot-testsuite/docker
./build-image.sh

cd $workdir

docker run --net $DOCKER_NET_NAME \
	--name=$container_name \
	-e TESTSUITE_REPO=$TESTSUITE_REPO \
	-e TESTSUITE_BRANCH=$REPO_BRANCH \
	-e IAM_BASE_URL=https://iam.local.io \
	-e REMOTE_URL=http://selenium-hub:4444/wd/hub \
	-e BROWSER=$BROWSER \
	italiangrid/iam-robot-testsuite


## Copy reports
rm -rfv $workdir/reports

reportdir=$workdir/reports

mkdir $reportdir

docker cp $container_name:/home/tester/iam-robot-testsuite/reports $reportdir


## Stop services and cleanup
cleanup
