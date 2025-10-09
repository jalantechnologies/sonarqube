#!/bin/bash
set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd /home/projects/git/jalantechnologies/sonarqube

DOMAIN="sonarqube.platform.bettrhq.com"
EMAIL="developer@bettrhq.com"
CERT_PATH="./certbot/conf/live/$DOMAIN/fullchain.pem"

if [ ! -f "$CERT_PATH" ]; then
    echo "$(date) - Certificate not found, issuing first-time cert for $DOMAIN"
    docker-compose run --rm certbot certonly -n \
        --webroot --webroot-path /var/www/certbot/ \
        -d "$DOMAIN" \
        -m "$EMAIL" \
        --agree-tos
else
    echo "$(date) - Certificate exists for $DOMAIN, attempting renewal if due"
    docker-compose run --rm certbot renew
fi

docker-compose restart
echo "$(date) - Restarted SonarQube stack successfully"
