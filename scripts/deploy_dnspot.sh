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
yum install git vim  openssl-devel -y
yum groupinstall 'Development Tools' -y

# Build protobuf
git clone https://github.com/google/protobuf
cd protobuf/
./autogen.sh
./configure --prefix=/usr
make
make check
make install
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
ldconfig # refresh shared library cache.
cd ..

# Build protobuf-c
git clone https://github.com/protobuf-c/protobuf-c
cd protobuf-c/
./autogen.sh
./configure --prefix=/usr
make
make install
cd ..

# Build fstrm
yum install epel-release -y
yum install fstrm fstrm-devel -y

# Get and build Bind9
git clone https://source.isc.org/git/bind9.git
cd bind9
./configure --prefix=/usr/local/named --enable-dnstap
make
make install















#################################### Get libraries ####################################
git clone https://github.com/google/protobuf
git clone https://github.com/protobuf-c/protobuf-c
git clone https://github.com/farsightsec/fstrm

protobuf-devel protobuf-compiler


###########################
apt-get install protobuf-c-compiler protobuf-compiler libprotobuf-c0 libprotobuf-c0-dev autoconf libtool libevent-dev libxml2 libxml2-dev -y

git clone https://github.com/farsightsec/fstrm
cd fstrm
./autogen.sh && ./configure && make && make check && make install
ldconfig

git clone https://source.isc.org/git/bind9.git
cd bind9
./configure --prefix /usr --sysconfdir /etc/bind --with-openssl --enable-threads --with-libxml2 --enable-dnstap

############################



# Build protobuf

make
make install
ldconfig

sudo touch /etc/named.conf
sudo named -V
sudo named -g

cd /etc
sudo rndc-confgen -a

sudo named
sudo ps -ef|grep named
sudo rndc status


#yum install protobuf-devel libevent libevent-devel protobuf-c-compiler protobuf-compiler openssl-devel -y
yum install epel-release -y
yum install fstrm fstrm-devel -y
cd protobuf
./autogen.sh
./configure --prefix=/usr
make
make check
make install
ldconfig # refresh shared library cache.
#autoreconf -i
#./configure --prefix=/usr
#make
#make install
cd ..

# Build protobuf-c
cd protobuf-c
./autogen.sh && ./configure --prefix=/usr && make && make install
#autoreconf -i
#./configure
#make
#make install
cd ..

# Build fstrm
cd fstrm
./autogen.sh && ./configure && make && make check && make install
#autoreconf -i
#./configure
#make
#make install
cd ..

#################################### Install/Setup Bind + DNStap ####################################
git clone https://source.isc.org/git/bind9.git
cd bind9
./configure --prefix=/usr/local/named --enable-dnstap
make
make install

mkdir -p /var/log/dnstap
#cat > /etc/nanmed.conf << EOF
#
#dnstap{all;};
#dnstap-output file "/var/log/dnstap/dnstap.log"
#EOF


#################################### Bind9 systemD service ####################################
cat > /etc/systemd/system/bind.service << EOF
[Unit]
Description=Berkeley Internet Name Domain (DNS)
Wants=nss-lookup.target
Wants=named-setup-rndc.service
Before=nss-lookup.target
After=network.target
After=named-setup-rndc.service

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/named
Environment=KRB5_KTNAME=/etc/named.keytab
PIDFile=/run/named/named.pid

ExecStartPre=/bin/bash -c 'if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z /etc/named.conf; else echo "Checking of zone files is disabled"; fi'
ExecStart=/usr/sbin/named -u named $OPTIONS

ExecReload=/bin/sh -c '/usr/sbin/rndc reload > /dev/null 2>&1 || /bin/kill -HUP $MAINPID'

ExecStop=/bin/sh -c '/usr/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID'

PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

#################################### Install/Setup Filebeat ####################################
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

#
