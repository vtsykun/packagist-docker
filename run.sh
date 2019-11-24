#!/bin/bash

set -x
mkdir -p /var/www/.ssh/ && mkdir -p /root/.ssh/

touch /var/www/.ssh/known_hosts
chmod -R 600 /var/www/.ssh/*

echo " >> Creating the correct known_hosts file"
for _DOMAIN in $PRIVATE_REPO_DOMAIN_LIST ; do
    IFS=':' read -a arr <<< "${_DOMAIN}"
    if [[ "${#arr[@]}" == "2" ]]; then
        port="${arr[1]}"
        ssh-keyscan -t rsa,dsa -p "${port}" ${arr[0]} >> /var/www/.ssh/known_hosts
    else
        ssh-keyscan -t rsa,dsa $_DOMAIN >> /var/www/.ssh/known_hosts
    fi
done

cp -r /var/www/.ssh/* /root/.ssh && chmod -R 600 /root/.ssh/*
FILE=app/config/parameters.yml
if [ ! -f ${FILE} ]; then
  cp app/config/parameters.yml ${FILE}
fi

sed -i "s/database_host"\:".*/database_host"\:" $DATABASE_HOST/g" ${FILE}
sed -i "s/database_password"\:".*/database_password"\:" $DATABASE_PASSWORD/g" ${FILE}
sed -i "s/database_driver"\:".*/database_driver"\:" $DATABASE_DRIVER/g" ${FILE}
sed -i "s/database_name"\:".*/database_name"\:" $DATABASE_NAME/g" ${FILE}
sed -i "s/database_user"\:".*/database_user"\:" $DATABASE_USER/g" ${FILE}
sed -i "s/database_port"\:".*/database_port"\:" $DATABASE_PORT/g" ${FILE}
sed -i "s/packagist_dist_host"\:".*/packagist_dist_host"\:" https:\/\/$VIRTUAL_HOST/g" ${FILE}

# Additional script handler
if [ -f /var/tmp/data/handler.sh ]; then
    bash /var/tmp/data/handler.sh
fi

rm -rf var/cache/*
app cache:clear --env=prod && app cache:clear --env=dev

app doctrine:schema:update --force -v
DB_DRIVER=`cat ${FILE} | awk '/database_driver:/{ print $2 }'`
case "$DB_DRIVER" in
    pdo_pgsql)
        app doctrine:query:sql "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch" -vvv
    ;;
esac

if [[ -n ${ADMIN_USER} ]]; then
  app packagist:user:manager "$ADMIN_USER" --email="$ADMIN_EMAIL" --password="$ADMIN_PASSWORD" --admin
fi

chown www-data:www-data -R /var/www/

echo "Start supervisor"
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
