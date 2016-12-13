#!/bin/bash

set -xe

sh /generate_default_config.sh > /etc/nginx/conf.d/default.conf
nginx -g "daemon off;"