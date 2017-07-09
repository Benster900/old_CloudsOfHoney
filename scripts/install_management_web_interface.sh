#!/bin/bash

set -x
set -e

web_dir=$cloudsDir/server/web_interface

# Install virtualenv
pip install virtualenv
virtualenv $web_dir/app/env
. $web_dir/app/env/bin/activate
pip install --upgrade pip
pip install -r $web_dir/requirements.txt
pip install Flask-Security		

# Create web app app.vars
read -s -p "Enter clouduser MariDB password: " mysqlCloudUserPassword
python $web_dir/setup.py --dbUser clouduser --dbPass $mysqlCloudUserPassword --dbHost localhost --dbDatabase cloudsofhoney --dbHash pbkdf2_sha256 
cp $web_dir/app.vars $cloudsDir/backup

chown cloudsofhoney:nginx -R $web_dir

cat > /etc/systemd/system/cloudsofhoneywebgui.service << EOF
[Unit]
Description=uWSGI instance to serve CloudsOfHoney Web Interface
After=network.target

[Service]
User=cloudsofhoney
Group=nginx
WorkingDirectory=$web_dir
Environment="PATH=$web_dir/app/env/bin"
ExecStart=$web_dir/app/env/bin/uwsgi --ini web_interface.ini

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start cloudsofhoneywebgui
sudo systemctl enable cloudsofhoneywebgui

sslKey="$(cat /etc/nginx/conf.d/kibana.conf | grep -w "ssl_certificate_key" | awk '{print $2}' | rev | cut -c 2- | rev)"
sslCert="$(cat /etc/nginx/conf.d/kibana.conf | grep -w "ssl_certificate" | awk '{print $2}' | rev | cut -c 2- | rev)"

cat > /etc/nginx/conf.d/cloudsofhoney.conf << EOF
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name _;
	return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate $sslCert;
    ssl_certificate_key $sslKey;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;


    location / {
        include uwsgi_params;
        uwsgi_pass unix:$web_dir/web_interface.sock;
    }
}
EOF

systemctl enable nginx
systemctl restart nginx

# Set SELinux permissions
yum install -y policycoreutils-python

curl --insecure https://localhost
cat /var/log/audit/audit.log | grep nginx | grep denied | audit2allow -M mynginx
semodule -i mynginx.pp

