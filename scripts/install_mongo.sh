#!/bin/bash

set -x
set -e

################################## Install/Setup Mongo ##################################
cat > /etc/yum.repos.d/mongodb.repo << EOF
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOF

yum -y update
yum -y install mongodb-org mongodb-org-server
pip install pymongo

systemctl enable mongod
systemctl start mongod

