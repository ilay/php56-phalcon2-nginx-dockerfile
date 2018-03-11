FROM ubuntu:trusty

ENV DEBIAN_FRONTEND noninteractive

# add NGINX official stable repository
RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list

# add PHP5.6 unofficial repository (https://launchpad.net/~ondrej/+archive/ubuntu/php)
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/php.list

# install packages
RUN apt-get update && \
    apt-get -y --force-yes --no-install-recommends install \
    supervisor \
    nginx \
    php5.6-cli php5.6-fpm php5.6-common php5.6-mysql php5.6-dev libpcre3-dev gcc make php5.6-mysql php5.6-memcached git vim

#RUN apt-get update && \
#    apt-get -y --force-yes --no-install-recommends install \
#    supervisor \
#    curl \
#    nginx \
#    php5-cli php5-fpm php5-common php5-mysql php5-dev libpcre3-dev gcc make php5-mysql php5-memcached git vim

# Build Phalcon 2
WORKDIR /tmp
RUN git clone --depth=1 git://github.com/phalcon/cphalcon.git
WORKDIR /tmp/cphalcon
RUN git remote set-branches origin '2.0.x'
RUN git fetch --depth 1 origin 2.0.x
RUN git checkout 2.0.x
WORKDIR /tmp/cphalcon/build
RUN sudo ./install
RUN echo [phalcon] >> /etc/php/5.6/mods-available/phalcon.ini
RUN echo extension=phalcon.so >> /etc/php/5.6/mods-available/phalcon.ini
RUN echo [phalcon] >> /etc/php/5.6/fpm/conf.d/50-phalcon.ini
RUN echo extension=phalcon.so >> /etc/php/5.6/fpm/conf.d/50-phalcon.ini
RUN echo [phalcon] >> /etc/php/5.6/cli/conf.d/50-phalcon.ini
RUN echo extension=phalcon.so >> /etc/php/5.6/cli/conf.d/50-phalcon.ini

# configure NGINX as non-daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# configure php-fpm as non-daemon
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/5.6/fpm/php-fpm.conf

# clear apt cache and remove unnecessary packages
RUN apt-get autoclean && apt-get -y autoremove

# add a phpinfo script for INFO purposes
RUN echo "<?php phpinfo();" >> /var/www/html/index.php

# NGINX mountable directories for config and logs
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# NGINX mountable directory for apps
VOLUME ["/var/www"]

# copy config file for Supervisor
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# backup default default config for NGINX
RUN cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# copy local defualt config file for NGINX
COPY config/nginx/default /etc/nginx/sites-available/default

# php-fpm5.6 will not start if this directory does not exist
RUN mkdir /run/php

# NGINX ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
