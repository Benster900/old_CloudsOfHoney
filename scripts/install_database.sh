#!/bin/bash

set -x
set -e

################################## Install/Setup MariaDB ##################################
yum install mariadb-server mariadb-client mysql-devel -y
pip install MySQL-python 
systemctl enable mariadb
systemctl start mariadb

mysql_secure_installation
read -s -p "Enter password for MariaDB root user: " mysqlpassword

mysql --user="root" --password="$mysqlpassword" --execute="CREATE DATABASE cloudsofhoney;"
read -s -p "Enter password for MariaDB clouduser: " mysqlpassword
mysql --user="root" --password="$mysqlpassword" --execute="CREATE USER 'clouduser'@'localhost' IDENTIFIED BY '$mysqlpassword';"
mysql --user="root" --password="$mysqlpassword" --execute="GRANT ALL ON cloudsofhoney.* TO 'clouduser'@'localhost'; FLUSH PRIVILEGES;"


################################## Install/Setup RethinkDB ##################################
sudo wget http://download.rethinkdb.com/centos/7/`uname -m`/rethinkdb.repo \
          -O /etc/yum.repos.d/rethinkdb.repo
sudo yum install rethinkdb -y
pip install rethinkdb

cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/instance1.conf
sed -i 's/# http-port=8080/http-port=8080/g' /etc/rethinkdb/instances.d/instance1.conf
sed -i 's/# bind=127.0.0.1/bind=0.0.0.0/g' /etc/rethinkdb/instances.d/instance1.conf

# Setup SSL encryption
sslKey="$(cat /etc/nginx/conf.d/kibana.conf | grep -w "ssl_certificate_key" | awk '{print $2}' | rev | cut -c 2- | rev)"
sed -i "s#http-port=8080#http-port=8080\nhttp-tls-key=$sslKey#g" /etc/rethinkdb/instances.d/instance1.conf

sslCert="$(cat /etc/nginx/conf.d/kibana.conf | grep -w "ssl_certificate" | awk '{print $2}' | rev | cut -c 2- | rev)"
sed -i "s#http-port=8080#http-port=8080\nhttp-tls-cert=$sslCert#g" /etc/rethinkdb/instances.d/instance1.conf

systemctl enable rethinkdb
systemctl start rethinkdb














#https://rethinkdb.com/docs/security/
