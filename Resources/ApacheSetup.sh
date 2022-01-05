#!/bin/bash

set -o verbose
set -o xtrace

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes apache2
apt-get install --yess curl

export MYUUID=$(curl "http://169.254.169.254/latest/meta-data/hostname")

mkdir -p /var/www/${MYUUID}
chown -R www:www /var/www

cat << EOFSITE > /etc/apache2/sites-available/heat-lb-asg.conf
<VirtualHost *:80>
  ServerAdmin webmaster@${MYUUID}
  DocumentRoot /var/www/${MYUUID}
  <Directory /var/www/${MYUUID}>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Require all granted
    Allow from all
  </Directory>
  ErrorLog /var/www/${MYUUID}-error.log
  CustomLog /var/www/${MYUUID}-access.log combined
</VirtualHost>
EOFSITE

cat << EOFHTML > /var/www/${MYUUID}/index.html
<html>
  <body>
    <h1>
      ${MYUUID}
    </h1>
  </body>
</html>
EOFHTML

unlink /etc/apache2/sites-enabled/000-default.conf
ln -s /etc/apache2/sites-available/heat-lb-asg.conf /etc/apache2/sites-enabled/heat-lb-asg.conf

systemctl restart apache2.service
systemctl status apache2.service
