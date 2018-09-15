#!/usr/bin/env bash

touch ./renew_cert.sh

chmod a+x ./renew_cert.sh

python /data/ssl/acme_tiny.py --account-key /data/ssl/account.key --csr /data/ssl/domain.csr --acme-dir /data/challenges/ > /data/ssl/signed.crt || exit

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > /data/ssl/intermediate.pem

cat /data/ssl/signed.crt /data/ssl/intermediate.pem > /data/ssl/chained.pem

nginx -s reload

crontab -e 0 0 1 * * /data/ssl/renew_cert.sh 2>> /data/ssl/acme_tiny.log

