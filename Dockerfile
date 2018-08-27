FROM ubuntu:xenial

ENV DEBIAN_FRONTEND=noninteractive LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y locales language-pack-en-base

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
	software-properties-common cron nano curl supervisor ssh npm nginx \
	iputils-ping net-tools less

RUN add-apt-repository ppa:git-core/ppa && add-apt-repository ppa:ondrej/php && \
    apt-get update && apt-get install -y --force-yes --no-install-recommends git redis-server \
    php7.1-fpm php7.1-cli php7.1-common php7.1-dev php7.1-pgsql php7.1-mysql php7.1-curl php7.1-redis \
    php7.1-xmlrpc php7.1-mbstring php7.1-apcu php7.1-xsl php7.1-intl php7.1-zip php7.1-bz2

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.1/fpm/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 1024M/"  /etc/php/7.1/cli/php.ini && \
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.1/fpm/php.ini && \
    sed -i "1 a\apc.shm_size=128M" /etc/php/7.1/fpm/php.ini

COPY supervisor* /etc/supervisor/conf.d/
COPY config/packagist.conf  /etc/nginx/sites-enabled/default
COPY config/nginx.conf  /etc/nginx/nginx.conf
COPY config/cron.conf /tmp/cron.conf
COPY scripts/app.sh /usr/local/bin/app

RUN crontab -u www-data /tmp/cron.conf && mkdir -p /run/php/ && \
    chmod +x /usr/local/bin/app

USER www-data
RUN git clone https://github.com/vtsykun/private-packagist.git /var/www/packagist && \
    cp /var/www/packagist/app/config/parameters.yml.dist /var/www/packagist/app/config/parameters.yml && \
    composer install --no-interaction --no-suggest --prefer-dist --working-dir /var/www/packagist

USER root
WORKDIR /var/www/packagist

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 80
