#!/bin/bash

IAM_REPO=${IAM_REPO:-https://github.com/indigo-iam/iam.git}
IAM_REPO_BRANCH=${IAM_REPO_BRANCH:-develop}
set -xe
work_dir=$(mktemp -d -t 'iam_dt_XXXX')
reports_dir=${work_dir}/reports

echo "Travis env"
echo ${TRAVIS_REPO_SLUG}
echo ${TRAVIS_JOB_ID}
echo ${TRAVIS_JOB_NUMBER}
function tar_reports_and_logs(){
  docker cp deploymenttest_iam-robot-testsuite_1:/home/tester/iam-robot-testsuite/reports ${reports_dir}
  docker-compose logs --no-color iam >${reports_dir}/iam.log
  docker-compose logs --no-color iam-be >${reports_dir}/iam-be.log
  pushd ${work_dir} 
  tar cvzf reports.tar.gz reports
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
set +e
docker-compose up -d 
docker-compose logs -f iam-robot-testsuite
tar_reports_and_logs

if [ $? != 0 ]; then
  echo "Testsuite failed"
  exit 1
fi

docker-compose stop
