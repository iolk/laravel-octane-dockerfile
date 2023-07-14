# Adapted from https://github.com/joseluisq/alpine-php-fpm/blob/master/8.2-fpm/Dockerfile

FROM ghcr.io/roadrunner-server/roadrunner:2023.2 AS roadrunner
FROM composer:2.5.8 AS composer
FROM iolk/supercronic AS supercronic

FROM php:8.2-alpine

# Install roadrunner - https://roadrunner.dev/
COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr

# Install composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Install supercronic
COPY --from=supercronic /usr/bin/supercronic /usr/bin/supercronic

# Accepted values: production | development
ARG APP_ENV=production

ENV DEV_BUILD_PKGS \
    linux-headers \
    autoconf \
    bash \
    curl \
    g++ \
    gcc \
    git \
    make \
    cmake

RUN set -eux \
    # Dependencies
    && apk add --no-cache \
    $DEV_BUILD_PKGS \
    postgresql-client \
    supervisor \
    freetds \
    freetype \
    gmp \
    icu-libs \
    libgmpxx \
    libintl \
    libjpeg-turbo \
    libpng \
    libpq \
    libgd \
    libtool \
    libwebp \
    libxpm \
    libxslt \
    libzip \
    tzdata \
    && true \
    \
    # Development dependencies
    && if [ ${APP_ENV} = "development" ] ; then \
    apk add --no-cache \
    nodejs \
    ; fi \
    && true \
    \
    # Build dependencies
    && apk add --no-cache --virtual .build-deps \
    autoconf \
    bzip2-dev \
    cmake \
    curl-dev \
    freetds-dev \
    freetype-dev \
    g++ \
    gcc \
    gettext-dev \
    git \
    gmp-dev \
    icu-dev \
    imagemagick-dev \
    imap-dev \
    krb5-dev \
    libc-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    librdkafka-dev \
    libssh2-dev \
    libwebp-dev \
    libxml2-dev \
    libxpm-dev \
    libxslt-dev \
    libzip-dev \
    openssl-dev \
    pcre-dev \
    pkgconf \
    postgresql-dev \
    rabbitmq-c-dev \
    tidyhtml-dev \
    unixodbc-dev \
    vips-dev \
    yaml-dev \
    zlib-dev \
    && true \
    \
    # Install gd
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include  \
    && docker-php-ext-install -j$(nproc) gd \
    && true \
    \
    # Install bcmath
    && docker-php-ext-install -j$(nproc) bcmath \
    && true \
    \
    # Install bz2
    && docker-php-ext-install -j$(nproc) bz2 \
    && true \
    \
    # Install pdo_pgsql
    && docker-php-ext-install -j$(nproc) pdo_pgsql \
    && true \
    \
    # Install pgsql
    && docker-php-ext-install -j$(nproc) pgsql \
    && true \
    \
    # Install redis
    && pecl install redis \
    && docker-php-ext-enable redis \
    && true \
    \
    # Install soap
    && docker-php-ext-install -j$(nproc) soap \
    && true \
    \
    # Install pcntl
    && docker-php-ext-install -j$(nproc) pcntl \
    && true \
    \
    # Install sockets (needed by Octane)
    && CFLAGS="${CFLAGS:=} -D_GNU_SOURCE" docker-php-ext-install -j$(nproc) \
    sockets \
    && docker-php-source extract \
    && true \
    \
    # Install zip
    && docker-php-ext-configure zip --with-zip \
    && docker-php-ext-install -j$(nproc) zip \
    && true \
    \
    # Clean up build packages
    && docker-php-source delete \
    && apk del .build-deps \
    && apk del $DEV_BUILD_PKGS \
    && rm -rf /tmp/pear \
    && true \
    \
    # Fix php.ini settings for enabled extensions
    && chmod +x "$(php -r 'echo ini_get("extension_dir");')"/* \
    # Shrink binaries
    && (find /usr/local/bin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && (find /usr/local/lib -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && (find /usr/local/sbin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && true

# Install locales
ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl
RUN set -eux \
    && apk add --no-cache $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
    && cd musl-locales-master \
    && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
    && cd .. && rm -r musl-locales-master \
    && apk del $MUSL_LOCALE_DEPS \
    && true

# Create rr config dir
RUN mkdir -p /etc/rr

COPY deploy/$APP_ENV/.rr.yaml /etc/rr/.rr.yaml
COPY deploy/$APP_ENV/supervisord* /etc/supervisor/conf.d/
COPY deploy/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint

RUN set -eux \
    # Set up entrypoint
    && chmod +x /usr/local/bin/docker-php-entrypoint \
    # Set up supercronic
    && mkdir -p /etc/supercronic \
    # Supervisor log fix
    && mkdir -p /var/log/supervisor

EXPOSE 80 6001

ENTRYPOINT ["docker-php-entrypoint"]

STOPSIGNAL SIGQUIT