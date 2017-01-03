################################## Install/Setup MariaDB ##################################
yum install mariadb-server mariadb-client -y
systemctl enable mariadb
systemctl start mariadb

mysql_secure_installation
read -s -p "Enter password for MariaDB root user: " mysqlpassword

mysql --user="root" --password="$mysqlpassword" --execute="DATABASE $cloudsofhoney;"
read -s -p "Enter password for MariaDB clouduser: " mysqlpassword
mysql --user="root" --password="$mysqlpassword" --execute="CREATE USER 'clouduser'@'localhost' IDENTIFIED BY '$mysqlpassword';"
mysql --user="root" --password="$mysqlpassword" --execute="GRANT ALL ON cloudsofhoney.* TO 'clouduser'@'localhost'; FLUSH PRIVILEGES;"


################################## Install/Setup RethinkDB ##################################
sudo wget http://download.rethinkdb.com/centos/7/`uname -m`/rethinkdb.repo \
          -O /etc/yum.repos.d/rethinkdb.repo
sudo yum install rethinkdb -y

cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/instance1.conf
sed -i 's/# http-port=8080/http-port=8080/g' /etc/rethinkdb/instances.d/instance1.conf
sed -i 's/# bind=127.0.0.1/bind=0.0.0.0/g' /etc/rethinkdb/instances.d/instance1.conf

systemctl enable rethinkdb
systemctl start rethinkdb

yum install python-pip
pip install rethinkdb

https://rethinkdb.com/docs/security/