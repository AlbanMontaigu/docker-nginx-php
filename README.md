# docker-nginx-php

## Introduction

This image aims to be my personal nginx + php-fpm middle server but you can use it if you want.

The base image is my [nginx](https://hub.docker.com/r/amontaigu/nginx/) image. This is customized to add **php-fpm** working together with nginx.

The **php-fpm** installation is done by compilation. The methodology is taken from [the official php-fpm image](https://hub.docker.com/_/php/) and its [source](https://github.com/docker-library/php/blob/c05f8260ab4b9371923c409d099f37c9eef863a7/5.6/fpm/Dockerfile).

Then I add some configuration tuning.

## Please note

**This image is tuned with :**

* Php [suhosin](https://suhosin.org/stories/index.html) for security
* Php [opcache](http://php.net/manual/fr/book.opcache.php) for performance

You could find some other performance / security tunings in configuration files that may change depending your needs.

## References and documentation

* [My nginx base image](https://github.com/AlbanMontaigu/docker-nginx/blob/master/Dockerfile)
* [An example of a php fpm nginx image](https://github.com/ngineered/nginx-php-fpm)
* [Supervisor tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps)
* [Another supervisor tutorial](https://docs.docker.com/articles/using_supervisord/)
* [Original php-fpm docker file](https://github.com/docker-library/php/blob/c05f8260ab4b9371923c409d099f37c9eef863a7/5.6/fpm/Dockerfile)

Don't hesitate to check the files of the project because they can contain more documentation and interesting links.

## Getting the source

On GitHub with my [docker-nginx-php](https://github.com/AlbanMontaigu/docker-nginx-php) project.

## You could be interested by

My [nginx](https://hub.docker.com/r/amontaigu/nginx/) docker image and it's [source](https://github.com/AlbanMontaigu/docker-nginx) on GitHub.

Then you will have a nginx front server.

And finally, you can look at my [nginx-php-plus](https://hub.docker.com/r/amontaigu/nginx-php-plus/) image and its [source](https://github.com/AlbanMontaigu/docker-nginx-php-plus) if you want more modules like gd, mbstring, exif, mysqli and so on in your default php installation.
