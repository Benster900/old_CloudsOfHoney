##################################### Install/Setup FirewallD #####################################
yum install firewalld -y

systemctl start firewalld
systemctl enable firewalld

firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https
firewall-cmd --zone=public --permanent --add-service=ssh
firewall-cmd --zone=public --permanent --add-port=5044/tcp
firewall-cmd --reload
