#!/bin/bash

# $1 privite key name
mkPriviteKey() {
    openssl genrsa 4096 > "$1"
}

# account
read -p 'please input the account key file name, default is [account]: ' -a account

if [ -z "$account" ]; then
    account="account"
fi

checkFile "$GENERATE_WORKDIR/$account".key mkPriviteKey

# domain
read -p 'please input the domain privite key, default is [domain]: ' -a domain

if [ -z "$domain" ]; then
    domain="domain"
fi

checkFile "$GENERATE_WORKDIR/$domain".key mkPriviteKey
