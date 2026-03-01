FROM ubuntu:24.04

LABEL maintainer="Agus Syahputra"

ARG PHP_VER=8.1
ARG APP_MODE=WordPress
ARG USERNAME=user1
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV C_ALL=C.UTF-8

# Instead of using ARG we use export because user don't need to set the environment vars.
# We set the env inline (using export) instead of ENV because we don't need to persist it after build.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt update && apt install -y --no-install-recommends \
    language-pack-en-base \
    software-properties-common \
    gpg-agent \
    && add-apt-repository -y ppa:ondrej/apache2 \
    && add-apt-repository -y ppa:ondrej/php \
    && apt update && apt install -y --no-install-recommends \
    sudo \
    git \
    apache2 \
    php${PHP_VER} \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt update && apt install -y --no-install-recommends \
    nano \
    curl \
    less \
    net-tools \
    dnsutils \
    iputils-ping \
    traceroute \
    php${PHP_VER}-xdebug \
    php${PHP_VER}-mysql \
    php${PHP_VER}-xml \
    php${PHP_VER}-curl \
    php${PHP_VER}-gd \
    php${PHP_VER}-zip \
    php${PHP_VER}-mbstring \
    && a2enmod rewrite \
    && rm /var/www/html/index.html \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# For Ubuntu 24.04, the default user is "ubuntu" with UID and GID 1000. We need to remove it to avoid conflicts with our custom user.
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Make home access more restrictive (default 755). Let o+x for Apache to be able to access it.
    && chmod 751 /home/user1 \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 440 /etc/sudoers.d/$USERNAME

USER user1

RUN mkdir /home/user1/bin && mkdir /home/user1/code

WORKDIR /home/user1

ENV PATH=/home/user1/bin:/home/user1/.config/composer/vendor/bin:$PATH

RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/home/user1/bin/ --filename=composer \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && echo "\n[ -s ~/.nvm/nvm.sh ] && source ~/.nvm/nvm.sh" >> .bashrc

RUN if test $(echo "${APP_MODE}" | tr '[:upper:]' '[:lower:]') = "laravel" ;\
    then \
    # LARAVEL  
    sudo apt update && sudo apt install -y --no-install-recommends \
    php${PHP_VER}-sqlite3 \
    supervisor \
    && sudo rm -d /var/www/html \
    && sudo ln -s /home/user1/code/public/ /var/www/html \
    && mkdir /home/user1/code/public \
    && echo '<?php phpinfo();' > /home/user1/code/public/index.php ;\
    else \
    # WORDPRESS
    sudo apt update && sudo apt install -y --no-install-recommends \
    php${PHP_VER}-soap \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod 550 wp-cli.phar \
    && ln -s /home/user1/wp-cli.phar /home/user1/bin/wp \
    && wp core download --path=/home/user1/code \
    && sudo rm -d /var/www/html \
    && sudo ln -s /home/user1/code/ /var/www/html ;\
    fi \
    && sudo chown -R user1:www-data /home/user1/code \
    && sudo chmod -R 775 /home/user1/code \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# RUN git clone --depth 1 https://github.com/vrana/adminer /var/www/html/adminer

COPY files/php.ini /etc/php/${PHP_VER}/apache2/conf.d/99-custom.ini
COPY files/apache.conf /etc/apache2/conf-available/custom.conf
COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN sudo ln -s /etc/apache2/conf-available/custom.conf /etc/apache2/conf-enabled/custom.conf

EXPOSE 80    

# This is an anti-pattern because it runs the process in the background and then tails the logs, which is not ideal for Docker's process management and logging. 
# It can lead to issues with signal handling and log management.
# CMD ["/bin/sh", "-c", "sudo service apache2 start && sudo tail -f /var/log/apache2/access.log"]

# The standard practice is to run the process in the foreground so Docker can monitor it directly and capture its logs natively
CMD ["sudo", "apachectl", "-D", "FOREGROUND"]
