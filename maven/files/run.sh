#!/bin/bash

REPO="${REPO:-https://github.com/indigo-iam/iam.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"

mkdir -p $HOME/.m2/
wget -O $HOME/.m2/settings.xml https://raw.githubusercontent.com/italiangrid/docker-scripts/master/jenkins-slave-centos7/files/settings.xml

git clone $REPO
cd iam/
git checkout $REPO_BRANCH

cd iam-persistence/
mvn clean install

cd ..
mvn clean package