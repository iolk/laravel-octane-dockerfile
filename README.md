Laravel Octane Dockerfile
===

Lightweight & optimized Multi-Arch Docker Images (amd64/arm64) for PHP-8.2 with essential extensions on top of latest Alpine Linux ready for Laravel served by Octane and RoadRunner.

## Extensions & Packages

TODO

## Replacing sail image in dev

First install [sail](https://laravel.com/docs/master/sail).

Then install [octane](https://laravel.com/docs/master/octane) with-out roadrunner binary (already included within the container)

```bash
composer require laravel/octane
php artisan octane:install

# Required to run --watch
npm install --save-dev chokidar
```

Finally in `docker-compose.yml` change `laravel.test` with:

```yaml
laravel.test:
    image: 'iolk/laravel-octane:dev'
    ports:
        - '${APP_PORT:-80}:80'
    env_file:
        - .env
    volumes:
        - '.:/var/www'
    networks:
        - sail
```

