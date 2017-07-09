#!/bin/bash

set -x
set -e

################################## Install/Setup MariaDB ##################################
yum install mariadb-server mariadb-client mysql-devel -y
pip install MySQL-python
systemctl enable mariadb
systemctl start mariadb

# Set MariaDB root password
mysqladmin -u root password $mysql_root_pass

# Create cloudsofhoney database
mysql --user="root" --password="$mysql_root_pass" --execute="CREATE DATABASE cloudsofhoney;"

# Create clouduser
mysql --user="root" --password="$mysql_root_pass" --execute="CREATE USER '$mysql_coh_user'@'localhost' IDENTIFIED BY '$mysql_coh_pass';"

# Grant all privileges to clouduser
mysql --user="root" --password="mysql_root_pass" --execute="GRANT ALL ON cloudsofhoney.* TO '$mysql_coh_user'@'localhost'; FLUSH PRIVILEGES;"

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

