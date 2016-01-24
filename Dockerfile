###########################################################
# Dockerfile to build Wordpress Base Container
# Based on: ubuntu:latest
# DATE: 01/24/2016
############################################################

# Set the base image to Ubuntu 14.04 latest
FROM ubuntu:latest

# File Author / Maintainer
MAINTAINER Mohammad Ghaffari mg@barsavanet.ir

###################################################################
#  UPDATES & PRE-REQS  ******
###################################################################

RUN apt-get clean all && \
apt-get -y update && \
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 apache2-utils php5 php5-cli php5-common php5-mysql unzip wget git && \
apt-get clean && \
rm -fr /var/lib/apt/lists/*

# Remove locales other than english
RUN for x in `ls /usr/share/locale | grep -v en_GB`; do rm -fr /usr/share/locale/$x; done && \
for x in `ls /usr/share/i18n/locales/ | grep -v en_`; do rm -fr /usr/share/i18n/locales/$x; done

# Enable the mod_env module and headers
RUN a2enmod env ssl rewrite php5
RUN ln -s /etc/apache2/sites-available/wordpress.local.conf /etc/apache2/sites-enabled/wordpress.local.conf
COPY configs/apache-vh.conf /etc/apache2/sites-available/wordpress.local.conf

###################################################################
#  OVERRIDE ENABLED ENV VARIABLES  **
###################################################################

ENV MYSQL_SERVER db-local
ENV MYSQL_CLIENT localhost
ENV MYSQL_USER root
ENV MYSQL_PASS PAssw0rd
ENV MYSQL_DB wordpress
ENV WP_KEY "Check us out at www.appcontainers.com"
###################################################################
#  ADD REQUIRED APP FILES  ****
###################################################################

ADD README.md /tmp/

###################################################################
#****  Reset Apache CTN
###################################################################

# This section will handle undoing any install magic that the apache base container did on setup.
RUN rm -fr /etc/apache2/sites-available/apache_deb.conf && \
rm -fr /var/www/*; mkdir -p /var/www/html && \
rm -fr /tmp/install.log && \
chown -R www-data:www-data /var/www/html && \
ls -lah /var/www

###################################################################
#  APPLICATION INSTALL  *****
###################################################################

# Copy WordPress dir from git to the www folder
ADD wordpress/ /var/www/html/
# Copy the WP-Config file
RUN cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
RUN sed -i -e "s/define('DB_NAME', 'database_name_here')/define('DB_NAME', '$MYSQL_DB')/g" /var/www/html/wp-config.php
RUN sed -i -e "s/define('DB_USER', 'username_here')/define('DB_USER', '$MYSQL_USER')/g" /var/www/html/wp-config.php
RUN sed -i -e "s/define('DB_PASSWORD', 'password_here')/define('DB_PASSWORD', '$MYSQL_PASS')/g" /var/www/html/wp-config.php
RUN sed -i -e "s/define('DB_HOST', 'localhost')/define('DB_HOST', '$MYSQL_SERVER')/g" /var/www/html/wp-config.php
RUN sed -i -e "s/put your unique phrase here/$WP_KEY/g" /var/www/html/wp-config.php
RUN chown -R www-data:www-data /var/www

###################################################################
#  POST DEPLOY CLEAN UP  ******
###################################################################

# Ensure all services are stopped and fix ubuntu pid exists issue
RUN service apache2 stop

###################################################################
#  CONFIGURE START ITEMS  *******
###################################################################

# Set up Data Volume and Set docker run command.
CMD /bin/bash -c "service apache2 stop && /usr/sbin/apache2ctl -D FOREGROUND"

###################################################################
#  EXPOSE APPLICATION PORTS  ******
###################################################################

# Expose ports to other containers only
EXPOSE 80
EXPOSE 443
EXPOSE 3306
