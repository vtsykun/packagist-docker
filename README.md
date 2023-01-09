## DEPRECATED

The source code has been moved to the main repository.
Use a new [packeton/packeton](https://hub.docker.com/r/packeton/packeton) image 

### Packeton Docker image for v1 version (DEPRECATED).

Docker image for private packagist [packeton](https://github.com/vtsykun/packeton).

### Usage

To boot in standalone mode

```
docker run okvpn/packeton:latest
```

### Environment variables


* `PRIVATE_REPO_DOMAIN_LIST` - Save ssh fingerprints to known_hosts for this domain.

* `PACKAGIST_DIST_HOST` - Packagist host (example https://packagist.youcomany.org). 
Used for downloading the mirroring zip packages. (The host add into dist url for composer metadata).

* `DATABASE_DRIVER` - Specify database driver (pdo_mysql, pdo_pgsql)

* `DATABASE_HOST` -  Specify hostname of the database

* `DATABASE_PORT` - Specify port of the database (optional)

* `DATABASE_USER` - Specify user to use to authenticate to the database 

* `DATABASE_NAME` - Specify database name

* `DATABASE_PASSWORD` - Specify database password

* `ADMIN_USER` - Creating admin account, by default there is no admin user created so 
you won't be able to login to the packagist. To create an admin account you need to use 
environment variables to pass in an initial username and password (ADMIN_PASSWORD, ADMIN_EMAIL)

* `ADMIN_PASSWORD` - used together with `ADMIN_USER`

* `ADMIN_EMAIL` - used together with `ADMIN_USER`

* `GITHUB_NO_API` - used to disable GitHub api, (always clone repo using ssh key) `GITHUB_NO_API='true'`

The typical example `docker-compose.yml`

```yaml
version: '2'

services:
    postgres:
        hostname: postgres
        container_name: pgsql-pkg
        image: postgres:9.6
        volumes:
            - .docker/db:/var/lib/postgresql/data
        environment:
            POSTGRES_DB: packagist
            POSTGRES_PASSWORD: 123456
        expose:
            - "5432"
    packagist:
        image: okvpn/packeton:latest
        container_name: packagist
        hostname: packagist
        volumes:
            - .docker/data:/var/tmp/data
            - .docker/redis:/var/lib/redis
            - .docker/zipball:/var/www/packagist/app/zipball
            - .docker/composer:/var/www/.composer
            - .docker/ssh:/var/www/.ssh
        links:
            - "postgres"
        environment:
            PRIVATE_REPO_DOMAIN_LIST: bitbucket.org gitlab.com github.com
            PACKAGIST_DIST_HOST: https://pkg.okvpn.org
            DATABASE_HOST: postgres
            DATABASE_PORT: 5432
            DATABASE_DRIVER: pdo_pgsql
            DATABASE_USER: postgres
            DATABASE_NAME: packagist
            DATABASE_PASSWORD: 123456
            ADMIN_USER: admin
            ADMIN_PASSWORD: composer
            ADMIN_EMAIL: admin@example.com
            GITHUB_NO_API: 'true'
        ports:
            - 127.0.0.1:8088:80

```
