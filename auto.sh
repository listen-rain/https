#!/usr/bin/env bash

set -e

. ./func.sh
. ./autoUpdate.sh

# The specified directory
read -p 'please input the work dir, default is [/data/ssl]: ' -a workDir

workDir=$(checkDir $workDir '/data/ssl')

cd "$workDir"


########################### start ###########################

# make account
openssl genrsa 4096 > ./account.key

openssl genrsa 4096 > ./domain.key


# The Domain Name
domainName=$(specifyDomain)


# 单域名
openssl req -new -sha256 -key domain.key -subj "/CN=$domainName" > domain.csr


# 多域名
# openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:yoursite.com,DNS:www.yoursite.com,DNS:subdomain.yoursite.com")) > domain.csr


# 创建 challenge 目录
read -p 'Please Input The challenge Dir, default is [/data/challenges]: ' -a challengeDir

challengeDir=$(checkDir $challengeDir '/data/challenges')

# 指定 nginx 配置目录
read -p 'Please Input The Nginx Conf Dir, default is [/etc/nginx/conf.d]: ' -a nginxConfDir

if [ -z "$nginxConfDir" ]; then
    nginxConfDir="/etc/nginx/conf.d"
fi

if [ ! -d "$nginxConfDir" ]; then
    echo "No such directory!"
    exit 1
fi


# 指定 nginx server 配置文件
read -p "please input the challenge conf file name, default is [$domainName.challenge.conf]: " -a challengeConfFile

if [ -z "$challengeConfFile" ]; then
    challengeConfFile=$domainName.challenge.conf
fi

if [ -f "$nginxConfDir"/"$challengeConfFile" ]; then
    read -p 'the challenge conf file already exists, please input the challenge conf file name again: ' -a challengeConfFile

    if [ -z $challengeConfFile ]
    then
        challengeConfFile=$domainName.challenge2.conf
    fi
fi


# 创建 challenge 配置文件, 并写入内容
echo "Makeing challengeConfFile ....."

echo "server {
  listen 80;
  server_name $domainName;

  location /.well-known/acme-challenge/ {
    #存放验证文件的目录，需自行更改为对应目录
    alias $challengeDir;
    try_files \$uri =404;
  }

  location / {
    rewrite ^/(.*)$ https://$domainName/$1 permanent;
  }
}" | tee "$nginxConfDir"/"$challengeConfFile"


# 重启 nginx
echo "Reload Nginx ....."
nginx -s reload


# 生成证书
echo 'Creating Credential ......'
wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py

python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir "$challengeDir" > ./signed.crt

openssl dhparam -out ./dhparams.pem 2048

wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > ./intermediate.pem

cat signed.crt intermediate.pem > ./chained.pem


# 创建 nginx server 配置文件并写入内容
read -p "please input the tmp conf file name, default is [$domainName.tmp.conf]: " -a tmpConfFile

if [ -z "$tmpConfFile" ]; then
    tmpConfFile=$domainName.conf
fi

if [ -f "$nginxConfDir"/"$tmpConfFile" ]; then
    read -p 'the File already exists, please input the tmp conf file name again, default is [$domainName.tmp2.conf]: ' -a tmpConfFile

    if [ -z "$tmpConfFile" ]; then
        tmpConfFile=$domainName.tmp2.conf
    fi
fi


# nginx 配置文件的根目录
read -p "please input the root directory, default is [/www]: " -a rootDir

if [ ! -d "$rootDir" ]; then
    echo "No such directory"
    echo "Use Default /www"
    rootDir="/www"
fi

echo "
# php nginx conf example

server {
    listen 443 ssl;
    server_name $domainName;
    index index.html index.php;
    root  $rootDir;

    ssl on;                                        # nginx >= 1.5 版本无需写此行
    ssl_certificate $workDir/chained.pem;          # 根据你的路径更改
    ssl_certificate_key $workDir/domain.key;       # 根据你的路径更改
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    ssl_session_cache shared:SSL:50m;
    ssl_dhparam $workDir/dhparams.pem;            #根据你的路径更改
    ssl_prefer_server_ciphers on;

    location / {
        try_files \$uri @rewriteapp;
    }

    location @rewriteapp {
        rewrite ^(.*)$ /index.php\$1 last;
    }

    location ~ ^/.*\.php(/|$) {
        fastcgi_pass unix:/tmp/php-cgi.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)\$;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

server {
    listen 80;
    server_name $domainName;

    location /.well-known/acme-challenge/ {
        alias $challengeDir;
        try_files \$uri =404;
    }

    location / {
        rewrite ^/(.*)$ https://$domainName/$1 permanent;
    }
}" | tee "$nginxConfDir"/"$tmpConfFile"

echo 'Deleting challengeConfFile .....'
rm -f "$nginxConfDir"/"$challengeConfFile"

###################### end ####################################################


echo "Don't forget, exec: nginx -s reload"


################################ auto update ########################################

autoUpdate $workDir $challengeDir
