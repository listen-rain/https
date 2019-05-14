#!/usr/bin/env bash

autoUpdate () {
    echo -e "\n\033[32m \bcreating autoUpdate script renew_cert.sh ...\033[0m"

    renewFIle="renew_cert.sh"
    if [ -f $renewFIle ]; then
        read -p "$renewFIle already exists, overwrite?  [yes|no]: " -a overwrite
        if [[ "$overwrite" == "no" ]]; then
            echo -e "exiting ...\n"
            exit 0
        fi
    fi

    echo "
    python $1/acme_tiny.py --account-key $1/account.key \
        --csr $1/domain.csr \
        --acme-dir "$2" > $1/signed.crt

    if [ \$? -gt 0 ]; then
        exit \$?
    fi

    wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > $1/intermediate.pem

    cat $1/signed.crt $1/intermediate.pem > $1/chained.pem

    nginx -s reload
    " | tee ./$renewFIle

    chmod a+x ./$renewFIle
    echo -e "\033[33m \bDon't forget. exec: crontab -e '0 0 1 * * /usr/bin/sh $1/$renewFIle 2>> $1/acme_tiny.log' \033[0m"
    exit 0
}
