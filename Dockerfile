FROM ubuntu:xenial

ENV DEBIAN_FRONTEND=noninteractive LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y locales language-pack-en-base

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
	software-properties-common cron nano curl supervisor ssh nginx unzip \
	iputils-ping net-tools less

RUN add-apt-repository ppa:git-core/ppa && add-apt-repository ppa:ondrej/php && \
    apt-get update && apt-get install -y --force-yes --no-install-recommends git redis-server \
    php7.2-fpm php7.2-cli php7.2-common php7.2-dev php7.2-pgsql php7.2-mysql php7.2-curl php7.2-redis \
    php7.2-xmlrpc php7.2-mbstring php7.2-apcu php7.2-xsl php7.2-intl php7.2-zip php7.2-bz2

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require hirak/prestissimo

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.2/fpm/php-fpm.conf && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.2/cli/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.2/fpm/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 1024M/"  /etc/php/7.2/cli/php.ini && \
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.2/fpm/php.ini && \
    sed -i "1 a\apc.shm_size=256M" /etc/php/7.2/fpm/php.ini && \
    mkdir -p /var/www/packagist

ARG VERSION
ARG CACHEBUST
RUN git clone --recursive -b ${VERSION} https://github.com/vtsykun/packeton.git /var/www/packagist && \
    cp /var/www/packagist/app/config/parameters.yml.dist /var/www/packagist/app/config/parameters.yml && \
    sed -i "s/ path"\:".*/ path"\:" 'php:\/\/stdout'/g" /var/www/packagist/app/config/logger.yml && \
    rm -rf /var/www/packagist/.git && \
    composer install --no-interaction --no-suggest --prefer-dist --working-dir /var/www/packagist && \
    chown www-data:www-data -R /var/www

COPY supervisor* /etc/supervisor/conf.d/
COPY config/packagist.conf  /etc/nginx/sites-enabled/default
COPY config/nginx.conf  /etc/nginx/nginx.conf
COPY config/cron.conf /tmp/cron.conf
COPY scripts/app /usr/local/bin/app
COPY run.sh /root/run

RUN crontab -u www-data /tmp/cron.conf && mkdir -p /run/php/ && \
    chmod +x /usr/local/bin/app && chmod +x /root/run

WORKDIR /var/www/packagist

CMD ["/root/run"]

EXPOSE 80
