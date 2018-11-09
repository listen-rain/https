#!/usr/bin/env bash

autoUpdate ()
{

echo "
python $1/acme_tiny.py --account-key $1/account.key \
    --csr $1/domain.csr \
    --acme-dir "$2" > $1/signed.crt

if [ $? -gt 0 ]; then
    exit $?
fi

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > $1/intermediate.pem

cat $1/signed.crt $1/intermediate.pem > $1/chained.pem

nginx -s reload
" | tee ./renew_cert.sh

chmod a+x ./renew_cert.sh

echo "Don't forget, exec: crontab -e '0 0 1 * * $1/renew_cert.sh 2>> $1/acme_tiny.log' "

}
