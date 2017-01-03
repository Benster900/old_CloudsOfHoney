#!/bin/bash

set -x
set -e

web_dir=$cloudsDir/server/web_interface
# Install virtualenv
pip install virtualenv
virtualenv env
. ../env/bin/activate
pip install -r ../../requirements.txt

cat > /etc/systemd/system/cloudsofhoneywebgui.service << EOF
[Unit]
Description=uWSGI instance to serve CloudsOfHoney Web Interface
After=network.target

[Service]
User=cloudsofhoney
Group=nginx
WorkingDirectory=$web_dir
Environment="PATH=$web_dir/env/bin"
ExecStart=$web_dir/env/bin/uwsgi --ini web_interface.ini

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start cloudsofhoneywebgui
sudo systemctl enable cloudsofhoneywebgui

cat > /etc/nginx/conf.d/cloudsofhoney.conf << EOF
server {
    listen 80;
    server_name _;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:$web_dir/web_interface.sock;
    }
}
EOF

systemctl enable nginx
systemctl start nginx
