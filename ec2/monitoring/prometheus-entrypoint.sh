#!/bin/sh
set -e

envsubst '${PROD_EC2_HOST}' \
  < /etc/prometheus/prometheus.yml.template \
  > /tmp/prometheus.yml

exec /bin/prometheus \
  --config.file=/tmp/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=15d
