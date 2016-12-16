FROM nginx

ENV NGINX_SERVER_NAME=iam.local.io
ENV NGINX_PROXY_PASS=http://iam-be:8080

COPY files/wait-for-it.sh /
RUN chmod +x /wait-for-it.sh

COPY files/generate_default_config.sh /
RUN chmod +x /generate_default_config.sh

COPY files/run.sh /run.sh
RUN chmod +x /run.sh

COPY files/iam.key.pem /etc/ssl/private/
COPY files/iam.cert.pem /etc/ssl/certs/

CMD /run.sh