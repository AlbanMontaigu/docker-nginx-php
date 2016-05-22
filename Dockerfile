# ================================================================================================================
#
# NGINX with PHP-FPM
#
# @see https://github.com/AlbanMontaigu/docker-nginx/blob/master/Dockerfile
# @see https://github.com/ngineered/nginx-php-fpm
# @see https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps
# @see https://docs.docker.com/articles/using_supervisord/
# @see https://github.com/docker-library/php/blob/c05f8260ab4b9371923c409d099f37c9eef863a7/5.6/fpm/Dockerfile
# ================================================================================================================

# Base is a nginx install customized bye me
FROM amontaigu/nginx:1.9.15

# Maintainer
MAINTAINER alban.montaigu@gmail.com

# Environment configuration
ENV DEBIAN_FRONTEND="noninteractive" \
    PHP_VERSION="5.6.21" \
    PHP_SUHOSIN_VERSION_="0.9.38" \
    PHP_INI_DIR="/usr/local/etc/php" \
    PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx" \
    GPG_KEYS="6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3 0BD78B5F97500D450838F95DFE857D9A90D90EC1"

# System update & persistent / runtime deps && phpize deps
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y ca-certificates curl libpcre3 librecode0 libsqlite3-0 libxml2 --no-install-recommends \
    && apt-get install -y autoconf file g++ gcc libc-dev make pkg-config re2c --no-install-recommends \
    && apt-get install -y supervisor \
    && rm -r /var/lib/apt/lists/*

# Custom install custom command for php ext
COPY ./php/bin/docker-php-ext-* /usr/local/bin/
COPY ./php/etc/php-fpm.conf /usr/local/etc/
COPY ./php/etc/php/php.ini $PHP_INI_DIR/

# System preparation
RUN mkdir -p $PHP_INI_DIR/conf.d \
    && mkdir -p /var/log/supervisor \
    && chmod +x /usr/local/bin/docker-php-ext-* \
    && set -xe \
    && for key in $GPG_KEYS; do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done

# Build PHP from source !
# --enable-mysqlnd is included below because it's harder to compile after the fact the extensions are (since it's a plugin for several extensions, not an extension in itself)
RUN buildDeps=" \
        $PHP_EXTRA_BUILD_DEPS \
        libcurl4-openssl-dev \
        libpcre3-dev \
        libreadline6-dev \
        librecode-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
    " \
    && set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && curl -SL "http://php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror" -o php.tar.xz \
    && curl -SL "http://php.net/get/php-$PHP_VERSION.tar.xz.asc/from/this/mirror" -o php.tar.xz.asc \
    && gpg --verify php.tar.xz.asc \
    && mkdir -p /usr/src/php \
    && tar -xof php.tar.xz -C /usr/src/php --strip-components=1 \
    && rm php.tar.xz* \
    && cd /usr/src/php \
    && ./configure \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        $PHP_EXTRA_CONFIGURE_ARGS \
        --disable-cgi \
        --enable-mysqlnd \
        --with-curl \
        --with-openssl \
        --with-pcre \
        --with-readline \
        --with-recode \
        --with-zlib \
    && make -j"$(nproc)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
    && make clean

# Install required extensions
RUN docker-php-ext-install opcache

# Install php suhosin
# @see http://www.cyberciti.biz/faq/rhel-linux-install-suhosin-php-protection/
# @see https://github.com/stefanesser/suhosin
# @see http://www.suhosin.org/stories/install.html
RUN mkdir -p /usr/src/php-suhosin \
    && cd /usr/src/php-suhosin \
    && curl -SL "https://download.suhosin.org/suhosin-$PHP_SUHOSIN_VERSION_.tar.gz" -o suhosin.tgz \
    && tar -xof suhosin.tgz -C /usr/src/php-suhosin --strip-components=1 \
    && rm suhosin.tgz \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && echo 'extension=suhosin.so' > $PHP_INI_DIR/conf.d/ext-suhosin.ini

# NGINX tuning for PHP
COPY ./nginx/conf/sites-enabled/default.conf /etc/nginx/sites-enabled/default.conf
COPY ./nginx/conf/conf.d/proxy.conf /etc/nginx/conf.d/proxy.conf

# SUPERVISOR configuration
COPY ./supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Volumes to share
VOLUME ["/var/www", "/var/log/supervisor"]
WORKDIR /var/www

# Main process
CMD ["/usr/bin/supervisord"]
