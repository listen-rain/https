#!/usr/bin/env bash

# set -e


# root
if [ `id -u` -ne 0 ]; then
    echo -e "Please switch to root!\n"
    exit 1
fi


. ./func.sh
. ./autoUpdate.sh


# The specified directory
defaultWorkDir="/data/ssl"
read -p "please input the work dir, default is [$defaultWorkDir]: " -a workDir
workDir=$(checkDir $workDir $defaultWorkDir)
cd "$workDir"

#----------------- start -----------------------

# level
read -p "Please input the level, like [1024, 2048, 4096], default is 1024: " -a level
if [ -z $level ]; then
    level=1024
fi

# make account
sslAccount="./account.key"
if [ ! -f "$sslAccount" ];then
	openssl genrsa $level > $sslAccount
else
    echo -e "$sslAccount already exists, continue."
fi


# domain key
sslDomain="./domain.key"
if [ ! -f "$sslDomain" ];then
	openssl genrsa $level > $sslDomain
else
    echo -e "$sslDomain already exists, continue."
fi


# The Domain Name
domainName=$(specifyDomain)
if [ -z "$domainName" ]; then
	echo -e "\n\033[31m \bThe Domain Name Can't Be Null!\033[0m"
	exit 1
fi


# csr
sslCsr="./domain.csr"
if [ ! -f $sslCsr ]; then
    openssl req -new -sha256 -key $sslDomain -subj "/CN=$domainName" > $sslCsr
    if [ $? -ne 0 ];then
        echo -e "\033[31m \bVerifying Error! Please Check Again!\033[0m"
    fi
else
    echo "$sslCsr file already exists, continue."
fi


# challenge 目录
defaultChallengeDir="/data/challenges"
read -p "Please Input The challenge Dir, default is [$defaultChallengeDir]: " -a challengeDir
challengeDir=$(checkDir $challengeDir $defaultChallengeDir)


# 指定 nginx 配置目录
defaultNginxDir="/etc/nginx/conf.d"
read -p "Please Input The Nginx Conf Dir, default is [$defaultNginxDir]: " -a nginxConfDir
if [ -z "$nginxConfDir" ]; then
    nginxConfDir=$defaultNginxDir
fi

if [ ! -d "$nginxConfDir" ]; then
    echo "No such directory!"
    exit 1
fi


# 指定 nginx server 配置文件
defaultChallengeConfFile="$domainName.challenge.conf"
read -p "please input the challenge conf file name, default is [$defaultChallengeConfFile]: " -a challengeConfFile
if [ -z "$challengeConfFile" ]; then
    challengeConfFile=$defaultChallengeConfFile
fi

if [ -f "$nginxConfDir/$challengeConfFile" ]; then
    read -p "the challenge conf file already exists, del it? [yes|no]: " -a isDelFile

    if [ $isDelFile == "no" ]; then
        echo -e "Please confirm this $nginxConfDir/$challengeConfFile domain is $domainName"
        echo -e "continue..."
    else
        rm "$nginxConfDir/$challengeConfFile"

        # 创建 challenge 配置文件, 并写入内容
        echo "Making challengeConfFile ....."
        echo "server {
          listen 80;
          server_name $domainName;

          location /.well-known/acme-challenge/ {
            #存放验证文件的目录，需自行更改为对应目录
            alias $challengeDir/;
            try_files \$uri =404;
          }

          location / {
            rewrite ^/(.*)$ https://$domainName/\$1 permanent;
          }
        }" | tee "$nginxConfDir/$challengeConfFile"

        # 重启 nginx
        read -p "Are you sure you want to restart nginx? [yes|no]: " -a nginxRestart
        if [ "$nginxRestart" == "no" ];then
            echo -e "please restart nginx you self now."
            exit 0
        fi

        echo "Reload Nginx ....."
        nginx -s reload || systemcl restart nginx || service nginx restart
        if [ $? -ne 0 ];then
            echo  -e "Nginx restart failed."
            exit 1
        fi
    fi
fi


# 生成证书
echo 'Creating Credential ......'
if [ ! -f acme_tiny.py ]; then
    wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
fi
python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir "$challengeDir" > ./signed.crt
openssl dhparam -out ./dhparams.pem $level
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > ./intermediate.pem
cat signed.crt intermediate.pem > ./chained.pem


# 创建 nginx server 配置文件并写入内容
defaultTmpConf="$domainName.tmp.conf"
read -p "please input the tmp conf file name, default is [$defaultTmpConf]: " -a tmpConfFile
if [ -z "$tmpConfFile" ]; then
    tmpConfFile=$defaultTmpConf
fi

if [ -f "$nginxConfDir/$tmpConfFile" ]; then
    read -p "The File $nginxConfDir/$tmpConfFile already exists, overwrite it? [yes|no]: " -a overwrite
    if [ "$overwrite" == "no" ]; then
        autoUpdate $workDir $challengeDir

        exit 0
    else
        echo -e "continue... \n"
    fi
fi


# nginx 配置文件的根目录
read -p "please input the root directory, default is [/www]: " -a rootDir
if [ ! -d "$rootDir" ]; then
    echo "No such directory"
    echo "Use Default /www"
    rootDir="/www"
fi

echo -e "creating config file $nginxConfDir/$tmpConfFile ..."
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
        alias $challengeDir/;
        try_files \$uri =404;
    }

    location / {
        rewrite ^/(.*)$ https://$domainName/\$1 permanent;
    }
}" | tee "$nginxConfDir/$tmpConfFile"

echo -e "\n\033[31m \bDeleting challengeConfFile .....\033[0m"
rm "$nginxConfDir/$challengeConfFile"
#-------------------- end ---------------------


echo -e "\n\033[33m \bDon't forget restart nginx !\033[0m"

#-------------------- auto update -----------------------

autoUpdate $workDir $challengeDir
