#!/usr/bin/env bash

cd $1

touch ./renew_cert.sh

chmod a+x ./renew_cert.sh

python ./acme_tiny.py --account-key ./account.key \
    --csr ./domain.csr \
    --acme-dir "$challengeDir" > ./signed.crt || exit

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > ./intermediate.pem

cat ./signed.crt ./intermediate.pem > ./chained.pem

# nginx -s reload

# crontab -e 0 0 1 * * "$workDir"/renew_cert.sh 2>> "$workDir"/acme_tiny.log

