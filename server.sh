#!/usr/bin/env bash

mkdir /data/challenges/

echo 'server {
  server_name $2;
  location ^~ /.well-known/acme-challenge/ {
    # 存放验证文件的目录，需自行更改为对应目录
    alias /data/challenges/;
    try_files $uri =404;
  }
  location / {
    rewrite ^/(.*)$ https://yoursite.com/$1 permanent;
  }
}' | tee $1

