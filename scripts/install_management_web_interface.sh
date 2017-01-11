#!/bin/bash

set -x
set -e

web_dir=$cloudsDir/server/web_interface

# Install virtualenv
pip install virtualenv
virtualenv $web_dir/app/env
. $web_dir/app/env/bin/activate
pip install -r $web_dir/requirements.txt

python $web_dir/setup.py

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
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
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

