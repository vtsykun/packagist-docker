<?php
namespace Dev;
use Composer\IO\NullIO;
use Incenteev\ParameterHandler\Processor;

require_once __DIR__ . '/vendor/autoload.php';

$processor = new Processor(new NullIO());
$processor->processFile([
    'file' => 'app/config/parameters.yml',
    'env-map' => [
        'database_driver' => 'DATABASE_DRIVER',
        'database_host' => 'DATABASE_HOST',
        'database_port' => 'DATABASE_PORT',
        'database_name' => 'DATABASE_NAME',
        'database_user' => 'DATABASE_USER',
        'database_password' => 'DATABASE_PASSWORD',
        'mailer_transport' => 'MAILER_TRANSPORT',
        'mailer_host' => 'MAILER_HOST',
        'mailer_user' => 'MAILER_USER',
        'mailer_password' => 'MAILER_PASSWORD',
        'mailer_from_email' => 'MAILER_FROM_EMAIL',
        'mailer_from_name' => 'MAILER_FROM_NAME',
        'mailer_encryption' => 'MAILER_ENCRYPTION',
        'mailer_port' => 'MAILER_PORT',
        'mailer_auth_mode' => 'MAILER_AUTH_MODE',
        'redis_dsn' => 'REDIS_DSN',
        'trusted_proxies' => 'TRUSTED_PROXIES',
        'trusted_hosts' => 'TRUSTED_HOSTS',
        'packagist_dist_host' => 'PACKAGIST_DIST_HOST',
        'github_no_api' => 'GITHUB_NO_API'
    ]
]);
