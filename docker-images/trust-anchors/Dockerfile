FROM centos:7

COPY EGI-trustanchors.repo igi-test-ca.repo /etc/yum.repos.d/

RUN yum -y install epel-release && yum -y update
RUN yum -y install igi-test-ca ca-policy-egi-core fetch-crl && fetch-crl || true

VOLUME /etc/grid-security/certificates
