FROM ubuntu:22.04

LABEL maintainer="Agus Syahputra"

ARG APP_VER=7.4
ARG APP_MODE=WordPress
ARG USERNAME=user1
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV C_ALL=C.UTF-8

# Instead of using ARG we use export because user don't need to set the environment vars.
# We set the env inline (using export) instead of ENV because we don't need to persist it after build.
RUN export DEBIAN_FRONTEND=noninteractive \
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
    php${APP_VER}
# && rm -rf /var/lib/apt/lists/*

RUN apt install -y --no-install-recommends \
    nano \
    curl \
    less \
    php${APP_VER}-xdebug \
    php${APP_VER}-mysql \
    php${APP_VER}-xml \
    php${APP_VER}-curl \
    php${APP_VER}-gd \
    php${APP_VER}-zip \
    php${APP_VER}-mbstring \
    && a2enmod rewrite \
    && echo 'xdebug.mode=debug' >> /etc/php/${APP_VER}/apache2/php.ini \
    && rm /var/www/html/index.html

COPY files/apache.conf /etc/apache2/conf-available/custom.conf

RUN ln -s /etc/apache2/conf-available/custom.conf /etc/apache2/conf-enabled/custom.conf \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Make home access more restrictive (default 755). Let o+x for Apache to be able to access it.
    && chmod 751 /home/user1 \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 440 /etc/sudoers.d/$USERNAME

USER user1

RUN mkdir /home/user1/bin && mkdir /home/user1/code

COPY --chown=user1:user1 files/composer.sh /home/user1

WORKDIR /home/user1

ENV PATH=/home/user1/bin:/home/user1/.config/composer/vendor/bin:$PATH

RUN sh composer.sh && mv composer.phar /home/user1/bin/composer \
    && composer g require psy/psysh:@stable \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash \
    && echo "\n[ -s ~/.nvm/nvm.sh ] && source ~/.nvm/nvm.sh" >> .bashrc

RUN if test $(echo "${APP_MODE}" | tr '[:upper:]' '[:lower:]') = "laravel" ;\
    then \
    sudo apt install -y --no-install-recommends \
    php${APP_VER}-sqlite3 \
    supervisor \
    && sudo rm -d /var/www/html \
    && sudo ln -s /home/user1/code/public/ /var/www/html \
    && mkdir /home/user1/code/public \
    && echo '<?php phpinfo();' > /home/user1/code/public/index.php ;\
    else \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod 550 wp-cli.phar \
    && ln -s /home/user1/wp-cli.phar /home/user1/bin/wp \
    && wp core download --path=/home/user1/code \
    && sudo rm -d /var/www/html \
    && sudo ln -s /home/user1/code/ /var/www/html ;\
    fi \
    && sudo chown -R user1:www-data /home/user1/code \
    && sudo chmod -R 775 /home/user1/code

# RUN git clone --depth 1 https://github.com/vrana/adminer /var/www/html/adminer

COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chown=user1:user1 --chmod=775 files/start-container /home/user1/bin/start-container

EXPOSE 80    

CMD sudo service apache2 start && sudo tail -f /var/log/apache2/access.log
