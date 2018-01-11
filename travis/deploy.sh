#!/bin/bash
set -e
[[ -n "${IAM_DEPLOYMENT_TEST_DEBUG}" ]] && set -x

IAM_REPO=${IAM_REPO:-https://github.com/indigo-iam/iam.git}
IAM_REPO_BRANCH=${IAM_REPO_BRANCH:-develop}
TRAVIS_REPO_SLUG=${TRAVIS_REPO_SLUG:-indigo-iam/iam-deployment-test}
TRAVIS_JOB_ID=${TRAVIS_JOB_ID:-0}
TRAVIS_JOB_NUMBER=${TRAVIS_JOB_NUMBER:-0}
REPORT_REPO_URL=${REPORT_REPO_URL:-}

work_dir=$(mktemp -d -t 'iam_dt_XXXX')
reports_dir=${work_dir}/reports

function tar_reports_and_logs(){
  if [ ! -d ${reports_dir} ]; then
    mkdir -p ${reports_dir}
  fi
  docker-compose logs --no-color iam >${reports_dir}/iam.log
  docker-compose logs --no-color iam-be >${reports_dir}/iam-be.log
  docker-compose logs --no-color client >${reports_dir}/client.log
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
cd iam
git checkout ${IAM_REPO_BRANCH}
cd compose/deployment-test
docker-compose up -d 

set +e
docker-compose logs -f iam-robot-testsuite

ts_ec=$(docker inspect deploymenttest_iam-robot-testsuite_1 -f '{{.State.ExitCode}}')

tar_reports_and_logs
set -e
upload_reports_and_logs
docker-compose stop

if [ ${ts_ec} != 0 ]; then
  exit 1
fi
