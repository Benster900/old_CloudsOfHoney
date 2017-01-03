cat > $cloudsDir/server/web_interface.ini << EOF
[uwsgi]
module = wsgi

master = true
processes = 5

socket = web_interface.sock
chmod-socket = 660
vacuum = true

die-on-term = true
EOF

cat > /etc/systemd/system/cloudsofhoneywebgui.service << EOF
[Unit]
Description=uWSGI instance to serve CloudsOfHoney Web Interface
After=network.target

[Service]
User=clouds
Group=nginx
WorkingDirectory=\$cloudsDir
Environment="PATH=/home/user/myproject/myprojectenv/bin"
ExecStart=/home/user/myproject/myprojectenv/bin/uwsgi --ini myproject.ini

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start myproject
sudo systemctl enable myproject

cat > << /etc/nginx/conf.d/web_interface.conf

EOF

systemctl enable cloudsofhoneywebgui
systemctl start cloudsofhoneywebgui
