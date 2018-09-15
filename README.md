# 自动生成 Let's Encrypt 安全证书

### [ducomentation](https://github.com/diafygi/acme-tiny)

### [friend-link](https://www.fanhaobai.com/2016/12/lets-encrypt.html)

## 准备工作 

- 如果将要配置 https 的域名已经配置主机，先注释此域名所有的主机配置

- 域名解析一定要正确，一定要解析二级域名(不带 www 的)

- 为防止不必要的麻烦，所有自己指定的目录必须带上后面的 '/'

- 错误日志在 acme_tiny.log

- 暂时支持单域名，多域名的有时间会加上

## 使用

```bash
git clone https://github.com/listen-rain/https-automake.git

cd https

sh autoMakeKey.sh
```

## 添加自动更新证书的定时任务

crontab -e
```bash
0 0 0 1 * "$workDir"/renew_cert.sh &>> $workDir/acme_tiny.log
```

有问题请发邮件至 zhufengwei@aliyun.com
