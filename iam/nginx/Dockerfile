FROM nginx
COPY ./wait-for-it.sh /
RUN chmod +x /wait-for-it.sh
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY iam.key.pem /etc/ssl/private/
COPY iam.cert.pem /etc/ssl/certs/
