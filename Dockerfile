FROM php:7.3-fpm-alpine

RUN apk --no-cache add nginx openssl supervisor curl \
    git patch bash nano sudo icu openssh unzip redis shadow

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# workaround for https://github.com/docker-library/php/issues/240
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		postgresql-dev \
		icu-dev \
		coreutils \
		curl-dev \
		libxml2-dev \
		bzip2-dev \
		libxslt-dev \
		libzip-dev \
	; \
	\
	export CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS"; \
	\
	pecl install -o -f redis apcu; \
	docker-php-ext-enable redis apcu; \
    docker-php-ext-install xsl zip pdo pdo_pgsql pdo_mysql intl sysvsem opcache \
        bz2 xmlrpc mbstring iconv curl pcntl; \
    runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	echo $runDeps; \
	apk add --no-cache $runDeps; \
	\
	apk del --no-network .build-deps;

ARG VERSION=master
RUN set -eux; \
    mkdir -p /var/www/packagist; \
    git clone --recursive -b ${VERSION} https://github.com/vtsykun/packeton.git /var/www/packagist; \
    cp /var/www/packagist/app/config/parameters.yml.dist /var/www/packagist/app/config/parameters.yml; \
    rm -rf /var/www/packagist/.git; \
    composer global require hirak/prestissimo; \
    composer install --no-interaction --no-suggest --no-dev --prefer-dist --working-dir /var/www/packagist; \
    chown www-data:www-data -R /var/www; \
    rm -rf /root/.composer

COPY php/www.conf /usr/local/etc/php-fpm.d/zzz-docker.conf
COPY php/php.ini /usr/local/etc/php/conf.d/90-php.ini
COPY supervisor/* /etc/supervisor/conf.d/
COPY php/supervisord.conf /etc/supervisor
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY php/env-map.php /var/www/packagist/
COPY php/app.php /var/www/packagist/web/
COPY php/app /usr/local/bin/app
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN set -eux; \
    mkdir -p /run/php/; \
    chmod +x /usr/local/bin/app /usr/local/bin/docker-entrypoint.sh; \
    usermod -d /var/www www-data; \
    chown www-data:www-data /var/lib/nginx /var/lib/nginx/tmp

WORKDIR /var/www/packagist
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
