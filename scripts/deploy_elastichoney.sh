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


################################## Install/Seutp elastichoney ##################################
# Create user
useradd elastichoney -d /home/elastichoney -s /bin/bash -g users

# Download elastichoney
cd /opt
git clone https://github.com/jordan-wright/elastichoney.git
cd /opt/elastichoney
eleasticHoneyDir=$(pwd)

# install and setup golang
yum install golang -y

echo ‘export GOROOT=/usr/lib/golang
export GOBIN=$GOROOT/bin
export GOPATH=/home/golang
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin’ > /etc/profile.d/go.sh

source ~/.bashrc
source /etc/profile
ldconfig

go get || true
go build

# Create log file
mkdir logs

# Make start file
cat > start.sh << EOF
#!/bin/bash
./elastichoney -config="config.json" -log="logs/elastichoney.log" &
pid=\$!
echo \$pid
echo \$pid > elastichoney.pid
EOF

# Make stop file
cat > stop.sh << EOF
#!/bin/bash
pid=\$(cat elastichoney.pid)
kill -9 \$pid
rm -rf elastichoney.pid
EOF

#Fix permissions for cowrie user
chown elastichoney:users -R $eleasticHoneyDir
su elastichoney -c "chmod +x start.sh"
su elastichoney -c "chmod +x stop.sh"

# Systemd
cat > /etc/systemd/system/elastichoney.service << EOF
[Unit]
Description=elastichoneyHoneypot
After=network.target
#Wants=syslog.target
#Wants=mysql.service

[Service]
Type=forking
User=elastichoney
Group=users
ExecStart=$eleasticHoneyDir/start.sh
ExecStop=$eleasticHoneyDir/stop.sh
ExecReload=$eleasticHoneyDir/stop.sh && sleep 10 && $eleasticHoneyDir/start.sh
WorkingDirectory=$eleasticHoneyDir
Restart=on-failure
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

systemctl enable elastichoney
systemctl start elastichoney


################################## Install/Setup FirewallD ##################################
yum install firewalld -y || true

systemctl start firewalld || true
systemctl enable firewalld || true


firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --zone=public --permanent --add-port=9200/tcp
firewall-cmd --zone=public --permanent --add-port=22/tcp
firewall-cmd --reload


################################## Install/Setup Filebeat ##################################
# If filebeat exists and is reporting to logstash just add new paths
if rpm -qa | grep -qw filebeat; then

# Just add config file
cat > /etc/filebeat/conf.d/elastichoney.yml << EOF
filebeat.prospectors:
- paths:
  - /opt/elastichoney/logs/elastichoney.log
  fields:
    sensorID: $result
    sensorType: honeypot
  document_type: elastichoney
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
cat > /etc/filebeat/conf.d/elastichoney.yml << EOF
filebeat.prospectors:
- paths:
  - /opt/elastichoney/logs/elastichoney.log
  fields:
    sensorID: $result
    sensorType: honeypot
  document_type: elastichoney
EOF


fi
systemctl restart filebeat
