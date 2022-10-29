FROM ubuntu:22.04

ARG VER=7.4
ARG USERNAME=user1
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Instead of using ARG we are using export because user don't need to set the environment vars
RUN export DEBIAN_FRONTEND=noninteractive \
    && export C_ALL=C.UTF-8 \
    && apt update \
    && apt install -y --no-install-recommends \
    language-pack-en-base \
    software-properties-common \
    gpg-agent \
    && add-apt-repository -y ppa:ondrej/apache2 \
    && add-apt-repository -y ppa:ondrej/php \
    && apt update && apt install -y --no-install-recommends \
    sudo \
    git \
    apache2 \
    php${VER}
# && rm -rf /var/lib/apt/lists/*

RUN apt install -y --no-install-recommends \
    nano \
    curl \
    less \
    php${VER}-xdebug \
    php${VER}-mysql \
    && a2enmod rewrite \
    && echo 'xdebug.mode=debug' >> /etc/php/${VER}/apache2/php.ini \
    && rm /var/www/html/index.html

COPY setup/apache.conf /etc/apache2/conf-enabled/custom.conf   

RUN chown -R www-data:www-data /var/www/html

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && usermod -a -G www-data user1 \
    && chmod 775 /var/www/html \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME    

USER user1    

RUN mkdir /home/user1/bin   

COPY --chown=user1:user1 setup/composer.sh /home/user1

WORKDIR /home/user1

ENV PATH=$PATH:/home/user1/bin:/home/user1/.config/composer/vendor/bin

RUN sh composer.sh && mv composer.phar /home/user1/bin/composer \
    && composer g require psy/psysh:@stable 

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && sudo chmod 554 wp-cli.phar \
    && ln -s /home/user1/wp-cli.phar /home/user1/bin/wp \
    && wp core download --path=/var/www/html    

RUN git clone --depth 1 https://github.com/vrana/adminer /var/www/html/adminer

COPY --chown=user1:www-data html/* /var/www/html/temp/

EXPOSE 80    

CMD sudo service apache2 start && sudo tail -f /var/log/apache2/access.log
