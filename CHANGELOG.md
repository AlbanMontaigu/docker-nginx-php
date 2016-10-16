
## 5.6.27 (2016-10-17)
- Update to php 5.6.27
- Set phar.readonly to On for security
- Set suhosin.executor.include.whitelist to "phar" to allow this for app that need it
- Added php-cli.ini to be more friendly for command line (and composer)
- Global rework of files to stick to official docker php style

## 5.6.26 (2016-10-16)
- Increasing netmask to 172.0.0.0/8 in set_real_ip_from in case of docker network change
- Update to amontaigu/nginx 1.11.5
- Update to php 5.6.26

## 5.6.25 (2016-09-03)
- Update to amontaigu/nginx 1.11.3
- Update to php 5.6.25
