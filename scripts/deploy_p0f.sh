#!/bin/bash

set -x
set -e

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

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

# Update system
yum update -y && yum upgrade -y
yum install git vim -y

################################## Install/Setup p0f ##################################
yum group install "Development Tools" -y
yum install libpcap libpcap-devel -y
git clone https://github.com/p0f/p0f.git
cd p0f
./build.sh

################################## Install/Setup Filebeat ##################################
# If filebeat exists and is reporting to logstash just add new paths
if rpm -qa | grep -qw filebeat; then

  sed '/\filebeat.prospectors:/a paths:
  - /var/log/p0f.log
document_type: p0f'/etc/filebeat/filebeat.yml

else
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

cat > /etc/filebeat/filebeat.yml << EOF
filebeat.prospectors:
- input_type: log

  # Paths that should be crawled and fetched. Glob based paths.
  paths:
    - /var/log/p0f.log
  document_type: p0f
output.logstash:
  hosts: ["$logstashServer:5044"]
EOF

fi
systemctl restart filebeat



#
