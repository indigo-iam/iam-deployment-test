#!/bin/bash

NGINX_SERVER_NAME="${NGINX_SERVER_NAME:-iam.local.io}"
NGINX_PROXY_PASS="${NGINX_PROXY_PASS:-http://iam-be:8080}"

echo "	
server {
  listen        443 ssl;
  server_name   $NGINX_SERVER_NAME;
  access_log    /var/log/nginx/iam_local_io.access.log  combined;

  ssl on;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_certificate      /etc/ssl/certs/iam.cert.pem;
  ssl_certificate_key  /etc/ssl/private/iam.key.pem;

  location / {
    proxy_pass              $NGINX_PROXY_PASS;
    proxy_set_header        X-Real-IP \$remote_addr;
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto https;
    proxy_set_header        Host \$http_host;
  }
}
"