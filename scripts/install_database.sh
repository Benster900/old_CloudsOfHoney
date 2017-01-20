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


################################## Install/Setup RethinkDB ##################################
sudo wget http://download.rethinkdb.com/centos/7/`uname -m`/rethinkdb.repo -O /etc/yum.repos.d/rethinkdb.repo
sudo yum install rethinkdb -y
pip install rethinkdb

cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/instance1.conf
sed -i 's/# http-port=8080/http-port=8000/g' /etc/rethinkdb/instances.d/instance1.conf
sed -i 's/# bind=127.0.0.1/bind=127.0.0.1/g' /etc/rethinkdb/instances.d/instance1.conf

systemctl enable rethinkdb
systemctl start rethinkdb

################################## Setup nginx ##################################
htpasswd -c /etc/nginx/htpasswdRethink.users rethinkdbadmin

# Setup SSL encryption
sslKey="$(cat /etc/nginx/conf.d/kibana.conf | grep -w "ssl_certificate_key" | awk '{print $2}' | rev | cut -c 2- | rev)"
sslCert="$(cat /etc/nginx/conf.d/kibana.conf | grep -w "ssl_certificate" | awk '{print $2}' | rev | cut -c 2- | rev)"

cat > /etc/nginx/conf.d/rethinkdb.conf << EOF
server {
        listen 8000 ssl;
        server_name _;

        root /usr/share/nginx/html;
        index index.html index.htm;

        ssl_certificate \$sslKey;
        ssl_certificate_key \$sslCert;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
        ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security max-age=15768000;

        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/htpasswdRethink.users;

	location / {
        	proxy_pass http://localhost:8000;
    	}
}
EOF

semanage port -a -t http_port_t -p tcp 8001
systemctl restart nginx
