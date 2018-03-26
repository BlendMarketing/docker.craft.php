FROM php:7.1-fpm-alpine
MAINTAINER Marc Tanis <marc@blendimc.com>

COPY php.ini /usr/local/etc/php/
COPY www.conf /usr/local/etc/php-fpm.d/

# Setup Extensions
ENV PHPREDIS_VERSION 3.1.4

RUN mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

RUN docker-php-source extract && \
  apk add --update --no-cache autoconf g++ make freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libmcrypt-dev git && \
  docker-php-ext-install mysqli && \
  docker-php-ext-install gd && \
  docker-php-ext-install pdo && \
  docker-php-ext-install pdo_mysql && \
  docker-php-ext-install mbstring && \
  docker-php-ext-install tokenizer && \
  docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ && \
   docker-php-ext-install gd && \
   docker-php-ext-install mcrypt && \
   docker-php-source delete && \
     rm -rf /var/cache/apk/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 
# Set craft cms version
ENV CRAFT_VERSION=2.6 CRAFT_BUILD=3009

ENV CRAFT_ZIP=Craft-$CRAFT_VERSION.$CRAFT_BUILD.zip

# Download the latest Craft (https://craftcms.com/support/download-previous-versions)
ADD https://download.buildwithcraft.com/craft/$CRAFT_VERSION/$CRAFT_VERSION.$CRAFT_BUILD/$CRAFT_ZIP /tmp/$CRAFT_ZIP

# Extract craft to webroot & remove default template files
RUN unzip -qqo /tmp/$CRAFT_ZIP 'craft/*' -d /var/www/ && \
    unzip -qqo /tmp/$CRAFT_ZIP 'public/index.php' -d /var/www/ && \
    rm -rf /var/www/craft/templates/* && \
    rm /tmp/$CRAFT_ZIP && \
    chown -Rf www-data:www-data /var/www

USER www-data
WORKDIR /var/www/
ONBUILD composer install
