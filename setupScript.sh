#!/bin/bash

set -x
set -e
cloudsDir=`dirname "$(readlink -f "$0")"`
SCRIPTS="$cloudsDir/scripts/"

cd $SCRIPTS

# Check if OS is CentOS
if [ -f /etc/redhat-release ]; then
  echo "[`date`] ========= Installing updates ========="
  yum update -y && yum upgrade -y
else
  echo "Please use CentOS to run this software :)"
fi


echo "[`date`] Starting Installation of CloudsOfHoney Managemnet Node"

echo "[`date`] ========= Installing ELK stack ========="
./install_elkstack.sh

echo "[`date`] ========= Installing Web Interface ========="
./install_management_web_interface.sh

echo "[`date`] ========= FirewallD setup ========="
./install_management_web_interface.sh

echo "[`date`] ========= CloudsOfHoney Server Install Finished ========="
echo ""






#
