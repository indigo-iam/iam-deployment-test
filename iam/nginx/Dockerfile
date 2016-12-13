FROM nginx

ENV NGINX_SERVER_NAME=iam.local.io
ENV NGINX_PROXY_PASS=http://iam-be:8080

COPY ./wait-for-it.sh /
RUN chmod +x /wait-for-it.sh

COPY generate_default_config.sh /
RUN chmod +x /generate_default_config.sh

COPY run.sh /run.sh
RUN chmod +x /run.sh

COPY iam.key.pem /etc/ssl/private/
COPY iam.cert.pem /etc/ssl/certs/

CMD /run.sh