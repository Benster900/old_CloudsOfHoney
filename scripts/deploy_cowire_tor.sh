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


# Create cloudsofhoney user and add ssh pub key for ansible retrieval
sshPubKey=$(curl -X GET http://$1/sshkeyauthentication/$result)

if [ $sshPubKey == "Not a valid known sensor please register sensor." ]; then
  echo $sshPubKey
  exit 1
else
    echo $sshPubKey

    # Create cloudsofhoney user
    adduser cloudsofhoney || true

    # Create .ssh directory and add ssh pub key
    mkdir -p /home/cloudsofhoney/.ssh || true
    chmod 700 /home/cloudsofhoney/.ssh || true
    echo $sshPubKey >> /home/cloudsofhoney/.ssh/authorized_keys || true
    chmod 700 /home/cloudsofhoney/.ssh || true
    chown cloudsofhoney:cloudsofhoney -R /home/cloudsofhoney
fi


################################## Change SSHd port ##################################
sed -i 's/#Port 22/Port 6969/g' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 6969/g' /etc/ssh/sshd_config
yum -y install policycoreutils-python
semanage port -m -t ssh_port_t -p tcp 6969
systemctl restart sshd

################################## Install/Setup Cowire ##################################
yum install -y epel-release -y
yum install -y gcc libffi-devel python-devel openssl-devel git python-pip pycrypto gmp gmp-devel mpfr-devel libmpc-devel -y
pip install --upgrade pip
pip install configparser pyOpenSSL tftpy twisted virtualenv

adduser cowire

cd /opt
git clone https://github.com/micheloosterhof/cowrie.git
mv cowrie cowire
cd /opt/cowire

# Install virtualenv
pip install virtualenv
virtualenv cowire-env
pip install -r requirements.txt

# Copy config
cp cowrie.cfg.dist cowrie.cfg

# Fix cowire systemd service
cp doc/systemd/cowrie.service doc/systemd/cowrie.service.bak
sed -i 's#cowrie#cowire#g' doc/systemd/cowrie.service
sed -i 's#/home/cowire/cowire#/opt/cowire#g' doc/systemd/cowrie.service
sed -i 's/Wants=mysql.service/#Wants=mysql.service/g' doc/systemd/cowrie.service
sed -i 's#PIDFile=/opt/cowire/var/run/cowire.pid#PIDFile=/opt/cowire/var/run/cowrie.pid#g' doc/systemd/cowrie.service

cp doc/systemd/cowrie.service /etc/systemd/system/cowire.service

#Fix permissions for cowrie user
chown -R cowire:users /opt/cowire/

systemctl enable cowire.service
systemctl start cowire.service

################################## Install/Setup Tor Hidden Service ##################################
cat > /etc/yum.repos.d/torproject.repo << EOF
[tor]
name=Tor repo
enabled=1
baseurl=http://deb.torproject.org/torproject.org/rpm/el/7/$basearch/
gpgcheck=1
gpgkey=http://deb.torproject.org/torproject.org/rpm/RPM-GPG-KEY-torproject.org.asc
 
[tor-source]
name=Tor source repo
enabled=1
autorefresh=0
baseurl=http://deb.torproject.org/torproject.org/rpm/el/7/SRPMS
gpgcheck=1
gpgkey=http://deb.torproject.org/torproject.org/rpm/RPM-GPG-KEY-torproject.org.asc
EOF

cat > /etc/tor/torrc << EOF
DataDirectory /var/lib/tor
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 22 127.0.0.1:2222

# Install tor
yum install -y tor
systemctl enable tor
systemctl start tor
EOF

systemctl enable tor
systemctl start tor

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

# Just add config file
cat > /etc/filebeat/conf.d/cowire.yml << EOF
filebeat.prospectors:
- paths:
    - /opt/cowire/log/*.json
  fields:
    sensorType: honeypot
    sensorID: $result
  document_type: cowire
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

#
cat > /etc/filebeat/conf.d/cowire.yml << EOF
filebeat.prospectors:
- paths:
    - /opt/cowire/log/*.json
  fields:
    sensorID: $result
    sensorType: honeypot
  document_type: cowire
EOF


fi
systemctl restart filebeat
