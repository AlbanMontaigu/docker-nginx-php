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
FROM amontaigu/nginx:1.11.5

# Maintainer
MAINTAINER alban.montaigu@gmail.com

# Environment configuration
ENV DEBIAN_FRONTEND="noninteractive" \
    PHP_VERSION="5.6.29" \
    PHP_FILENAME="php-${PHP_VERSION}.tar.xz" \
    PHP_SHA256="0ff352a433f73e2c82b0d5b283b600402518569bf72a74e247f356dacbf322a7" \
    PHP_SUHOSIN_VERSION_="0.9.38" \
    PHP_INI_DIR="/usr/local/etc/php" \
    PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx" \
    GPG_KEYS="6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3 0BD78B5F97500D450838F95DFE857D9A90D90EC1"

# System update & persistent / runtime deps && phpize deps
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y autoconf file g++ gcc libc-dev make pkg-config re2c --no-install-recommends \
    && apt-get install -y ca-certificates curl libedit2 libsqlite3-0 libxml2 xz-utils --no-install-recommends \
    && apt-get install -y supervisor \
    && rm -r /var/lib/apt/lists/*

# Custom install custom command for php ext
COPY ./php/bin/docker-php-* /usr/local/bin/
COPY ./php/etc/php/php.ini $PHP_INI_DIR/
COPY ./php/etc/php/php-cli.ini $PHP_INI_DIR/

# System preparation
RUN mkdir -p $PHP_INI_DIR/conf.d \
    && mkdir -p /var/log/supervisor \
    && chmod +x /usr/local/bin/docker-php-* \
    && set -xe \
	&& cd /usr/src \
	&& curl -fSL "https://secure.php.net/get/$PHP_FILENAME/from/this/mirror" -o php.tar.xz \
	&& echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c - \
	&& curl -fSL "https://secure.php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o php.tar.xz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done \
	&& gpg --batch --verify php.tar.xz.asc php.tar.xz \
	&& rm -r "$GNUPGHOME"

# Build PHP from source !
RUN set -xe \
	&& buildDeps=" \
		$PHP_EXTRA_BUILD_DEPS \
		libcurl4-openssl-dev \
		libedit-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
	" \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	\
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& ./configure \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
		--disable-cgi \
		\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
		\
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		\
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j"$(nproc)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	&& docker-php-source delete \
	\
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps

# FPM Configuration
RUN set -ex \
	&& cd /usr/local/etc \
	&& if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x don't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
	fi
COPY ./php/etc/php-fpm.d/*.conf /usr/local/etc/php-fpm.d/
COPY ./php/etc/php-fpm.conf /usr/local/etc/

# Install required extensions
RUN docker-php-ext-install opcache \
    && docker-php-ext-enable opcache

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
    && make install

# Extension configuration files
COPY ./php/etc/php/conf.d/* $PHP_INI_DIR/conf.d/

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
