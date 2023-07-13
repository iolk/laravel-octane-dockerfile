#!/bin/sh

while [ true ]
do
    php /code/artisan schedule:run --verbose --no-interaction &
    sleep 60
done
