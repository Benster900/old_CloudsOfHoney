#!/bin/bash

set -x
set -e

################################## Install/Setup MariaDB ##################################
yum install mariadb-server mariadb-client mysql-devel -y
pip install MySQL-python
systemctl enable mariadb
systemctl start mariadb

mysql_secure_installation

read -s -p "Enter password for MariaDB root user: "  mysqlRootPassword
mysql --user="root" --password="$mysqlRootPassword" --execute="CREATE DATABASE cloudsofhoney;"
read -s -p "Enter password for MariaDB clouduser user: " mysqlCloudUserPassword
mysql --user="root" --password="$mysqlRootPassword" --execute="CREATE USER 'clouduser'@'localhost' IDENTIFIED BY '$mysqlCloudUserPassword';"
mysql --user="root" --password="$mysqlRootPassword" --execute="GRANT ALL ON cloudsofhoney.* TO 'clouduser'@'localhost'; FLUSH PRIVILEGES;"

################################## Install/Setup Mongo ##################################
cat > /etc/yum.repos.d/mongodb.repo << EOF
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOF

yum -y update
yum -y install mongodb-org mongodb-org-server
pip install pymongo

systemctl enable mongod
systemctl start mongod

