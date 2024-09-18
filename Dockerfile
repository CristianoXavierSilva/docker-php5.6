#Usar a imagem oficial do Composer para obter o binário
FROM composer:2.2 AS composer_stage

# Use a imagem oficial do PHP 5.6 com Apache
FROM php:5.6-apache

# Instalar Composer versão 2.2 LTS
COPY --from=composer_stage /usr/bin/composer /usr/local/bin/composer

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list

WORKDIR /var/www/html

# Copiar arquivos de configuração para o contêiner
COPY ./apache2/sites-available /etc/apache2/sites-available/
COPY ./apache2/hosts /etc/hosts 

# Instalação de dependências e módulos do PHP
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libxslt-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    curl \
    git \
    zip \
    unzip \
    libonig-dev \
    libmagickwand-dev --no-install-recommends 

# Instalar extensões do PHP necessárias
RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-webp-dir=/usr/include/ 

RUN docker-php-ext-install curl \
    sockets \
    gd \
    mbstring \
    mcrypt \
    mysqli \
    pdo \
    pdo_mysql \
    intl \
    xml \
    zip \
    exif \
    soap \
    xsl \
    mcrypt

RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-enable intl
RUN docker-php-ext-enable mysqli
RUN docker-php-ext-enable pdo_mysql
RUN docker-php-ext-enable zip
RUN docker-php-ext-enable gd
RUN docker-php-ext-enable soap
RUN docker-php-ext-enable sockets

RUN BEFORE_PWD=$(pwd) \
    && mkdir -p /opt/xdebug \
    && cd /opt/xdebug \
    && curl -k -L https://github.com/xdebug/xdebug/archive/XDEBUG_2_5_5.tar.gz | tar zx \
    && cd xdebug-XDEBUG_2_5_5 \
    && phpize \
    && ./configure --enable-xdebug \
    && make clean \
    && sed -i 's/-O2/-O0/g' Makefile \
    && make \
    && make install \
    && cd "${BEFORE_PWD}" \
    && rm -r /opt/xdebug

# Copiar arquivo de configuração php.ini customizado
COPY ./php/php.ini /usr/local/etc/php/php.ini
COPY ./php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY ./apache2/conf-available/servername.conf /etc/apache2/conf-available/servername.conf

# Ativar módulos do Apache (rewrite, headers, ssl)
RUN a2enconf servername
RUN a2enmod rewrite headers ssl

RUN apt-get update
RUN apt-get install -y ca-certificates
RUN update-ca-certificates
RUN apt-get install --reinstall ca-certificates

# Reiniciar o Apache no final
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]

## Expondo Portas TCP
EXPOSE 80
EXPOSE 443