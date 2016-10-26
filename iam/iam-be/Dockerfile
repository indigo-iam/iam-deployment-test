FROM java:8

RUN mkdir /srv/indigo-iam

COPY files/iam-login-service.war /srv/indigo-iam/iam-login-service.war
COPY files/idp-metadata.xml /srv/indigo-iam/saml-idp/idp/shibboleth-idp/metadata/idp-metadata.xml

COPY files/wait-for-it.sh /

WORKDIR /srv/indigo-iam

CMD /wait-for-it.sh $WAIT_HOST:$WAIT_PORT -t $WAIT_TIMEOUT -- java $IAM_JAVA_OPTS -jar /srv/indigo-iam/iam-login-service.war
