#!/bin/bash

set -x
set -e

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if OS is CentOS
if [ -f /etc/redhat-release ]; then
  echo "[`date`] ========= Installing updates ========="
  yum update -y && yum upgrade -y

  # NTP Time Sync
  yum install ntp ntpdate ntp-doc -y
  systemctl enable ntpd
  systemctl start ntpd
  ntpdate pool.ntp.org || true
else
  echo "Please use CentOS to run this software :)"
fi

# Change hostname
if [ $(hostname) == "localhost.localdomain" ]; then
  hostnamectl set-hostname ip-$(hostname -I)
fi

# Get variables
server_url=$1
deploy_key=$2
hostName=$(hostname)


# Add new sensor to management nide
result=$(curl -X POST http://$1:5000/newsensor/`hostname`/$2)

if [ $result == "Honeypot not regisitered bad data*"]; then
  echo $result
  exit 1
else
  echo "Honeypot is registered with the following sensorID: $result"
fi


# Update system
yum update -y && yum upgrade -y
yum install git vim curl -y

################################## Install/Setup suricata ##################################
suricataInterface=$(ip a | grep '2:' | grep 'en' | awk '{print $2}' | rev | cut -c 2- | rev)
yum install -y epel-release
yum -y install gcc libpcap-devel pcre-devel libyaml-devel file-devel zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel tar make libnetfilter_queue-devel lua-devel
yum -y install suricata

sed -i "s/- interface: eth0/- interface: $(ip a | grep '2:' | grep 'en' | awk '{print $2}' | rev | cut -c 2- | rev)/g" /etc/suricata/suricata.yaml
sed -i 's#HOME_NET: "[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]"#HOME_NET: "$(hostname -I)"#g' /etc/suricata/suricata.yaml
sed -i 's/# payload: yes             # enable dumping payload in Base64/payload: yes             # enable dumping payload in Base64/g' /etc/suricata/suricata.yaml


systemctl enable suricata
systemctl start suricata











#
