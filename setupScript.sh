#!/bin/bash

set -x
set -e

# Check if OS is CentOS
if [ -f /etc/redhat-release ]; then
  echo "[`date`] ========= Installing updates ========="
  yum update -y && yum upgrade -y
else
  echo "Please use CentOS to run this software :)"
fi

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

################################## NTP Time Sync ##################################
yum install ntp ntpdate ntp-doc -y
systemctl enable ntpd
systemctl start ntpd
ntpdate pool.ntp.org || true

# Install software and update system
yum install epel-release -y
yum install vim net-tools htop wget gcc python-devel nginx -y
yum install policycoreutils-python -y
yum install python-pip -y
pip install --upgrade pip

# Set directory var
cloudsDir="$(pwd)"
SCRIPTS="$cloudsDir/scripts/"

# Create user
useradd cloudsofhoney

# Change permissions
chmod +x scripts/*
chown cloudsofhoney:nginx -R $cloudsDir
cd $SCRIPTS

echo "[`date`] Starting Installation of CloudsOfHoney Managemnet Node"
# Change hostname
read -p "Enter domain name: " -e domainName
if [ $(hostname) == "localhost.localdomain" ]; then
  hostnamectl set-hostname $domainName
fi

echo "[`date`] ========= Setup config file ========="
sed -i "s/MHN_DOMAIN_NAME = '127.0.0.1'/MHN_DOMAIN_NAME = '$domainName'/g" ../server/web_interface/config.py

echo "[`date`] ========= Installing postfix ========="
source install_smtp.sh

echo "[`date`] ========= Installing Ansible ========="
source install_ansible.sh

echo "[`date`] ========= Installing ELK stack ========="
source install_elkstack.sh

echo "[`date`] ========= Installing MariaDB ========="
cd $SCRIPTS
source install_database.sh
python install_init_databases.py $SCRIPTS

echo "[`date`] ========= Installing redis ========="
source install_redis.sh

echo "[`date`] ========= Installing Web Interface ========="
source install_management_web_interface.sh

echo "[`date`] ========= FirewallD setup ========="
./install_firewalld.sh

chown cloudsofhoney:nginx -R $cloudsDir
echo "[`date`] ========= CloudsOfHoney Server Install Finished ========="
echo ""






#
