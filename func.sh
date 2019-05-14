
checkDir ()
{
    if [ -z "$1" ]; then
        $1=$2
    fi

    if [ ! -d $1 ]; then
        mkdir -p $1 && sudo chmod -R 777 $1
    fi

    echo $1
}

errorReport()
{
    if [ $? -gt 0 ]; then
        exit $?
    fi
}

specifyDomain ()
{
    read -p 'please input the domain name, like [zhufengwei.com]: ' -a domainName

    domainName=$(echo $domainName | sed -n 's/^[ ]*\(.*\)[ ]*$/\1/p')

	echo $domainName
}

makeChallengeConfFile()
{
    # 创建 challenge 配置文件, 并写入内容
    echo "Making challengeConfFile ....."
    echo "server {
      listen 80;
      server_name $1;

      location /.well-known/acme-challenge/ {
        #存放验证文件的目录，需自行更改为对应目录
        alias $2/;
        try_files \$uri =404;
      }

      location / {
        rewrite ^/(.*)$ https://$1/\$1 permanent;
      }
    }" | tee "$3/$4"

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
}
