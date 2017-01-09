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
  yum install git vim -y

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


################################## Install/Setup p0f ##################################
p0fInterface=$(ip a | grep '2:' | grep 'en' | awk '{print $2}' |rev | cut -c 2- | rev)
yum group install "Development Tools" -y
yum install libpcap libpcap-devel -y

# Get and build p0f
cd /opt
git clone https://github.com/p0f/p0f.git
cd p0f/
./build.sh

# Create p0f user
useradd p0f -d /home/p0f -s /bin/bash -g users
mkdir -p /var/log/p0f
chown p0f:users -R /var/log/p0f

# Create systemD service
cat > /etc/systemd/system/p0f.service << EOF
[Unit]
Description=p0f service
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/opt/p0f/p0f -f /opt/p0f/p0f.fp -i $p0fInterface -u p0f -o /var/log/p0f/p0f.log


[Install]
WantedBy=multi-user.target
EOF

systemctl enable p0f
systemctl start p0f

################################## Install/Setup Filebeat ##################################
# If filebeat exists and is reporting to logstash just add new paths
if rpm -qa | grep -qw filebeat; then

# Just add config file
cat > /etc/filebeat/conf.d/p0f.yml << EOF
filebeat.prospectors:
- input_type: log
  paths:
    - /var/log/p0f/*.log
  fields:
    sensorID: $result
    sensorType: networksensor
  document_type: p0f
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
cat > /etc/filebeat/conf.d/p0f.yml << EOF
filebeat.prospectors:
- input_type: log
  paths:
    - /var/log/p0f/*.log
  fields:
    sensorID: $result
    sensorType: networksensor
  document_type: p0f
EOF


fi
systemctl restart filebeat
