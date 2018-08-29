#!/bin/bash

touch lock.txt
mkdir -p /var/www/.ssh/ && mkdir -p /root/.ssh/

if [ -d /var/tmp/ssh ]; then
    ls -l /var/tmp/ssh
    echo " >> Copying host ssh config from /var/tmp/ssh to /root/.ssh"
    cp -r /var/tmp/ssh/* /var/www/.ssh/
    chmod -R 600 /var/www/.ssh/*
fi

touch /var/www/.ssh/known_hosts
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
if [ -f ${FILE} ]; then
    sed -i "s/database_host"\:".*/database_host"\:" $DATABASE_HOST/g" ${FILE}
    sed -i "s/database_password"\:".*/database_password"\:" $DATABASE_PASSWORD/g" ${FILE}
    sed -i "s/database_driver"\:".*/database_driver"\:" $DATABASE_DRIVER/g" ${FILE}
    sed -i "s/database_name"\:".*/database_name"\:" $DATABASE_NAME/g" ${FILE}
    sed -i "s/database_user"\:".*/database_user"\:" $DATABASE_USER/g" ${FILE}
    sed -i "s/database_port"\:".*/database_port"\:" $DATABASE_PORT/g" ${FILE}
    sed -i "s/packagist_dist_host"\:".*/packagist_dist_host"\:" https:\/\/$VIRTUAL_HOST/g" ${FILE}
fi

# Additional script handler
if [ -f /var/tmp/data/handler.sh ]; then
    bash /var/tmp/data/handler.sh
fi

app doctrine:schema:update --force -v
DB_DRIVER=`cat ${FILE} | awk '/database_driver:/{ print $2 }'`
case "$DB_DRIVER" in
    pdo_pgsql)
        app doctrine:query:sql "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch" -vvv
    ;;
esac

rm -rf var/cache/* var/logs/*
app cache:clear --env=prod && app cache:clear --env=dev && \
    chown www-data:www-data -R /var/www/ && rm lock.txt

exit 0
