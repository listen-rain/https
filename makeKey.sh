#!/usr/bin/env bash

cd $GENERATE_WORKDIR

wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py

python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir /data/challenges/ > ./signed.crt

openssl dhparam -out dhparams.pem 2048

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem

cat signed.crt intermediate.pem > chained.pem

echo 'server {
  listen 443;
  server_name yoursite.com, www.yoursite.com;

  ssl on;
  ssl_certificate /data/ssl/chained.pem;          #根据你的路径更改
  ssl_certificate_key /data/ssl/domain.key;       #根据你的路径更改
  ssl_session_timeout 5m;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
  ssl_session_cache shared:SSL:50m;
  ssl_dhparam /data/ssl/dhparams.pem;            #根据你的路径更改
  ssl_prefer_server_ciphers on;

  ...the rest of your config
}' | tee $2

