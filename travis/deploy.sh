#!/bin/bash
set -e
[[ -n "${IAM_DEPLOYMENT_TEST_DEBUG}" ]] && set -x

IAM_REPO=${IAM_REPO:-https://github.com/indigo-iam/iam.git}
IAM_REPO_BRANCH=${IAM_REPO_BRANCH:-develop}
IAM_TESTSUITE_REPO=${IAM_TESTSUITE_REPO:-https://github.com/indigo-iam/iam-robot-testsuite.git}
IAM_TESTSUITE_REPO_BRANCH=${IAM_TESTSUITE_REPO_BRANCH:-develop}
TRAVIS_REPO_SLUG=${TRAVIS_REPO_SLUG:-indigo-iam/iam-deployment-test}
TRAVIS_JOB_ID=${TRAVIS_JOB_ID:-0}
TRAVIS_JOB_NUMBER=${TRAVIS_JOB_NUMBER:-0}
REPORT_REPO_URL=${REPORT_REPO_URL:-}
DOCKER_NET_NAME=${DOCKER_NET_NAME:-iam_default}

work_dir=$(mktemp -d -t 'iam_dt_XXXX')
reports_dir=${work_dir}/reports

function tar_reports_and_logs(){
  if [ ! -d ${reports_dir} ]; then
    mkdir -p ${reports_dir}
  fi
  docker-compose logs --no-color iam >${reports_dir}/iam.log
  docker-compose logs --no-color iam-be >${reports_dir}/iam-be.log
  docker-compose logs --no-color client >${reports_dir}/client.log
  docker-compose logs --no-color selenium-hub >${reports_dir}/selenium-hub.log
  docker-compose logs --no-color selenium-chrome >${reports_dir}/selenium-chrome.log
  docker-compose logs --no-color selenium-firefox >${reports_dir}/selenium-firefox.log
  docker cp deploymenttest_iam-robot-testsuite_1:/home/tester/iam-robot-testsuite/reports ${reports_dir}
  pushd ${work_dir} 
  tar cvzf reports.tar.gz reports
  popd
}

function upload_reports_and_logs() {
  pushd ${work_dir}
  if [ -r reports.tar.gz ]; then
    if [ -z "${REPORT_REPO_URL}" ]; then
      echo "Skipping report upload: REPORT_REPO_URL is undefined or empty"
      popd
      return 0
    fi
    REPORT_TARBALL_URL=${REPORT_REPO_URL}/${TRAVIS_REPO_SLUG}/${TRAVIS_JOB_ID}/reports.tar.gz
    curl --user "${REPORT_REPO_USERNAME}:${REPORT_REPO_PASSWORD}" \
      --upload-file reports.tar.gz \
      ${REPORT_TARBALL_URL}

    echo "Reports for this deployment test can be accessed at:"
    echo ${REPORT_TARBALL_URL}
  fi
  popd
}
  
function cleanup(){
  retcod=$?
  if [ $retcod != 0 ]; then
    echo "Error! Cleanup..."
    pushd ${work_dir}
    if [ -d iam ]; then
      cd iam/compose/deployment-test
      docker-compose stop
    fi
  fi
  exit $retcod
}

trap cleanup EXIT SIGINT SIGTERM SIGABRT

pushd ${work_dir}
git clone ${IAM_REPO} iam
pushd iam
git checkout ${IAM_REPO_BRANCH}
docker-compose down
docker-compose build
docker-compose up -d 
popd
popd

pushd ${work_dir}
git clone ${IAM_TESTSUITE_REPO}
pushd iam-robot-testsuite
git checkout ${IAM_TESTSUITE_REPO_BRANCH}

pushd docker
sh build-image.sh
popd
popd
# back to workdir
popd
# back to iam-deployment-test

DOCKER_NET_NAME=${DOCKER_NET_NAME} sh docker/selenium-grid/selenium_grid.sh start

docker run -d --name iam-robot-testsuite --net ${DOCKER_NET_NAME} -e TESTSUITE_BRANCH=${IAM_TESTSUITE_REPO_B${IAM_TESTSUITE_REPO_BRANCH} -e TESTSUITE_OPTS=--exclude=test-client -e IAM_BASE_URL=https://iam.local.io -e TIMEOUT=10 -e IMPLICIT_WAIT=1 -e REMOTE_URL=http://selenium-hub:4444/wd/hub  indigoiam/iam-robot-testsuite:latest

set +e
docker logs -f iam-robot-testsuite

ts_ec=$(docker inspect iam-robot-testsuite -f '{{.State.ExitCode}}')

tar_reports_and_logs
set -e
upload_reports_and_logs
docker rm iam-robot-testsuite

DOCKER_NET_NAME=${DOCKER_NET_NAME} sh docker/selenium-grid/selenium_grid.sh stop

pushd ${work_dir}
pushd iam
docker-compose stop
docker-compose down
popd
popd

if [ ${ts_ec} != 0 ]; then
  exit 1
fi
