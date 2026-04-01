#!/bin/sh
set -e

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

if [ -f "$CERT_PATH" ]; then
    echo "[nginx] SSL 인증서 확인 → HTTPS 모드로 시작"
    envsubst '${DOMAIN}' < /etc/nginx/templates/default-https.conf.template > /etc/nginx/conf.d/default.conf
else
    echo "[nginx] SSL 인증서 없음 → HTTP 전용 모드로 시작 (ACME 챌린지 대기)"
    cp /etc/nginx/templates/default-http.conf /etc/nginx/conf.d/default.conf
fi

exec nginx -g 'daemon off;'
