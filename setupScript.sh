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

# Install software and update system
yum update -y && yum upgrade -y
yum install vim net-tools htop wget -y

cloudsDir=`dirname "$(readlink -f "$0")"`
SCRIPTS="$cloudsDir/scripts/"

cd $SCRIPTS

echo "[`date`] Starting Installation of CloudsOfHoney Managemnet Node"
echo "[`date`] ========= Setup config file ========="
read -p "Enter domain name: " -e domainName
sed -i "s/MHN_DOMAIN_NAME = '127.0.0.1'/MHN_DOMAIN_NAME =$domainName /g"


echo "[`date`] ========= Installing postfix ========="
./install_smtp.sh

echo "[`date`] ========= Installing Ansible ========="
./install_ansible.sh

echo "[`date`] ========= Installing ELK stack ========="
./install_elkstack.sh

echo "[`date`] ========= Installing MariaDB ========="
./install_mariadb.sh

echo "[`date`] ========= Installing Web Interface ========="
./install_management_web_interface.sh
install_init_databases.py $SCRIPTS

echo "[`date`] ========= FirewallD setup ========="
./install_firewalld.sh

echo "[`date`] ========= CloudsOfHoney Server Install Finished ========="
echo ""






#
