#!/usr/bin/env bash

touch ./renew_cert.sh

chmod a+x ./renew_cert.sh

python "$workDir"/acme_tiny.py --account-key "$workDir"/account.key \
    --csr "$workDir"/domain.csr \
    --acme-dir "$challengeDir" > "$workDir"/signed.crt || exit

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > "$workDir"/intermediate.pem

cat "$workDir"/signed.crt "$workDir"/intermediate.pem > "$workDir"/chained.pem

nginx -s reload

# crontab -e 0 0 1 * * "$workDir"/renew_cert.sh 2>> "$workDir"/acme_tiny.log

