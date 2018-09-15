#!/usr/bin/env bash

# The specified directory
read -p 'please input the work dir, default is [/data/ssl]: ' -a workDir

if [ -z ""$workDir"" ]; then
    workDir="/data/ssl"
fi

if [ ! -d "$workDir" ]; then
    mkdir -p "$workDir" && sudo chmod -R 777 "$workDir"
fi

cd "$workDir"

########################### start ###########################

openssl genrsa 4096 > account.key

openssl genrsa 4096 > domain.key

# The Domain Name
read -p 'please input the domain name: ' -a domainName

if [ -z "$domainName" ]; then
    echo "The Domain Name Can't Be Null!"
    exit 1
fi

openssl req -new -sha256 -key domain.key -subj "/CN=$domainName" > domain.csr

read -p 'Please Input The challenge Dir, default is [/data/challenges]: ' -a challengeDir

if [ -z "$challengeDir" ]; then
    challengeDir="/data/challenges"
fi

if [ ! -d "$challengeDir" ]; then
    mkdir -p "$challengeDir" && sudo chmod -R 777 "$challengeDir"
fi

read -p 'Please Input The Nginx Conf Dir, default is [/etc/nginx/conf.d]: ' -a nginxConfDir

if [ -z "$nginxConfDir" ]; then
    nginxConfDir="/etc/nginx/conf.d"
fi

if [ ! -d "$nginxConfDir" ]; then
    echo "No such directory!"
    exit 1
fi

echo 'server {
  server_name www.yoursite.com yoursite.com subdomian.yoursite.com;
  location ^~ /.well-known/acme-challenge/ {
    #存放验证文件的目录，需自行更改为对应目录
    alias /data/challenges/;
    try_files $uri =404;
  }
  location / {
    rewrite ^/(.*)$ https://yoursite.com/$1 permanent;
  }
}' | tee $nginxConfDir/$domainName.ssl.challenge.conf

wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py

python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir /data/challenges/ > ./signed.crt

openssl dhparam -out ./dhparams.pem 2048

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > ./intermediate.pem

cat signed.crt intermediate.pem > ./chained.pem

echo "server {
  listen 443;
  server_name $domainName.com, www.$domainName.com;

  ssl on;                                        # nginx >= 1.5 版本无需写此行
  ssl_certificate $workDir/chained.pem;          # 根据你的路径更改
  ssl_certificate_key $workDir/domain.key;       # 根据你的路径更改
  ssl_session_timeout 5m;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
  ssl_session_cache shared:SSL:50m;
  ssl_dhparam $workDir/dhparams.pem;            #根据你的路径更改
  ssl_prefer_server_ciphers on;

  ...the rest of your config
}" | tee $nginxConfDir/ssl-tmp.conf

###################### end ####################################################

nginx -s reload

source ./auto.sh
