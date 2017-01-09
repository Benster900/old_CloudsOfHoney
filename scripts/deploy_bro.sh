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
  yum install git vim curl -y

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
result=$(curl -X POST http://$1/newsensor/`hostname`/$2)

if [ $result == "Honeypot not regisitered bad data*"]; then
  echo $result
  exit 1
else
  echo "Honeypot is registered with the following sensorID: $result"
fi


# Update system
yum update -y && yum upgrade -y
yum install git vim curl -y

################################## Install/Setup Bro IDS ##################################
# Install dependencies
yum install cmake make gcc gcc-c++ flex bison libpcap-devel openssl-devel python-devel swig zlib-devel git -y

# Install Bro
cd /opt
git clone --recursive git://git.bro.org/bro
cd bro
./configure
make
make install
export PATH=/usr/local/bro/bin:$PATH

# Configure Bro
broInterface=$(ip a | grep '2:' | grep 'en' | awk '{print $2}' |rev | cut -c 2- | rev)
echo $broInterface
sed -i "s#interface=eth0#interface=$broInterface#g" /usr/local/bro/etc/node.cfg

# Enable Bro JSON logging
sed -i 's#const use_json = F#const use_json = T#g' /usr/local/bro/share/bro/base/frameworks/logging/writers/ascii.bro

# Start Bro
/usr/local/bro/bin/broctl install
/usr/local/bro/bin/broctl start
/usr/local/bro/bin/broctl status

################################## Install/Setup Filebeat ##################################
# If filebeat exists and is reporting to logstash just add new paths
if rpm -qa | grep -qw filebeat; then

# Just add config file
cat > /etc/filebeat/conf.d/bro.yml << EOF
filebeat.prospectors:
- input_type: log
  paths:
    - /usr/local/bro/logs/current/*.log
  fields:
    sensorID: $result
    sensorType: networksensor
  document_type: bro
EOF

else
# Install filebeat
sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.repo << EOF
[elastic-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum install filebeat -y
systemctl enable filebeat
systemctl start filebeat

# Create config directory for filebeat
mkdir /etc/filebeat/conf.d/
cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak
cat > /etc/filebeat/filebeat.yml << EOF
filebeat:
  registry_file: /var/lib/filebeat/registry
  config_dir: /etc/filebeat/conf.d

output.logstash:
  hosts: ["$1:5044"]
EOF

# Just add config file
cat > /etc/filebeat/conf.d/bro.yml << EOF
filebeat.prospectors:
- input_type: log
  paths:
    - /usr/local/bro/logs/current/*.log
  fields:
    sensorID: $result
    sensorType: networksensor
  document_type: bro
EOF

fi
systemctl restart filebeat
