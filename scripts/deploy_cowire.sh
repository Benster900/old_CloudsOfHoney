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

################################## Change SSHd port ##################################
sed -i 's/#Port 22/Port 6969/g' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 6969/g' /etc/ssh/sshd_config
yum -y install policycoreutils-python
semanage port -m -t ssh_port_t -p tcp 6969
systemctl restart sshd

################################## Install/Setup Cowire ##################################
yum install -y epel-release -y
yum install -y gcc libffi-devel python-devel openssl-devel git python-pip pycrypto gmp gmp-devel mpfr-devel libmpc-devel -y
pip install -upgrade pip
pip install configparser pyOpenSSL tftpy twisted virtualenv
pip install -r requirements.txt

adduser cowrie
passwd cowrie
su - cowrie

git clone https://github.com/micheloosterhof/cowrie.git
cd cowire

virtualenv cowrie-env
mv cowrie.cfg.dist cowrie.cfg
sed -i 's/Wants=mysql.service/#Wants=mysql.service/g' doc/systemd/cowrie.service
sed -i 's/PIDFile=var/run/cowrie.pid/PIDFile=/home/cowrie/cowrie/var/run/cowrie.pid/g' doc/systemd/cowrie.service
mv doc/systemd/cowrie.service /etc/systemd/system/cowrie.service
systemctl enable cowrie.service
systemctl start cowrie.service


################################## Install/Setup FirewallD ##################################
yum install firewalld -y || true

systemctl start firewalld || true
systemctl enable firewalld || true


firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --zone=public --add-forward-port=port=22:proto=tcp:toport=2222 --permanent
firewall-cmd --zone=public --permanent --add-port=6969/tcp
firewall-cmd --reload



################################## Install/Setup Filebeat ##################################
# If filebeat exists and is reporting to logstash just add new paths
if rpm -qa | grep -qw filebeat; then

  sed '/\filebeat.prospectors:/a -
    # Paths that should be crawled and fetched. Glob based paths.
    paths:
      - /home/cowrie/cowrie/log/*.json
    document_type: cowire' /etc/filebeat/filebeat.yml

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
-
  # Paths that should be crawled and fetched. Glob based paths.
  paths:
    - /home/cowrie/cowrie/log/*.json
  document_type: cowire
output.logstash:
  hosts: ["$1:5044"]
EOF

fi
systemctl restart filebeat










##################################
