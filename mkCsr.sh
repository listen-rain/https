#!/usr/bin/env bash

mkCsr() {
    if [ ! -f "$1" ]; then
        read -p "please input the domainNameBind: " -a domainNameBind
        checkFileName $domainNameBind

        read -p 'please input the domain privite key, default is [domain]: ' -a domain

        if [ -z "$domain" ]; then
            domain="domain"
        fi

        checkFile "$GENERATE_WORKDIR/$domain".key mkPriviteKey

        openssl req -new -sha256 -key "$GENERATE_WORKDIR/$domain".key -subj "/CN=$domainNameBind" > "$1"
    fi
}

read -p "please input the csr file name, default is [$domain]: " -a csrFileName

if [ -z "$csrFileName" ]; then
    csrFileName="$domain"
fi

checkFile "$GENERATE_WORKDIR/$csrFileName".csr mkCsr
