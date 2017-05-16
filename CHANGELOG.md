
## 5.6.30 (2017-05-16)
- Update to php 5.6.30
- Update to nginx 1.13.0
- Update dockerfile and bin from official php docker build

## 5.6.29 (2017-01-02)
- Update to php 5.6.29
- Now use of base image with no upgrade (bad for layers reuse and stability)
- Update to nginx 1.11.8

## 5.6.27 (2016-10-17)
- Update to php 5.6.27
- Set phar.readonly to On for security (only for global not for cli)
- Set suhosin.executor.include.whitelist to "phar" to allow this for app that need it
- Added php-cli.ini to be more friendly for command line (and composer)
- Global rework of files to stick to official docker php style
- Extension configuration fixed

## 5.6.26 (2016-10-16)
- Increasing netmask to 172.0.0.0/8 in set_real_ip_from in case of docker network change
- Update to amontaigu/nginx 1.11.5
- Update to php 5.6.26

## 5.6.25 (2016-09-03)
- Update to amontaigu/nginx 1.11.3
- Update to php 5.6.25
