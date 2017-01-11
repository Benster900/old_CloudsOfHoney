#!/bin/bash

set -x
set -e

# Install ansible
yum install ansible -y

# generate ssh private and public key
su - cloudsofhoney -c 'ssh-keygen -t rsa -q -P "" -f $HOME/.ssh/id_rsa'

# Config ansible Config
sed -i 's/#remote_user = root/remote_user = cloudsofhoney/g' /etc/ansible/ansible.cfg
sed -i 's?#private_key_file = /path/to/file?private_key_file = /home/cloudsofhoney/.ssh/id_rsa?g' /etc/ansible/ansible.cfg

# Create config file to retrieve malware
cat $cloudsDir/server/ansible/ansible_malware_retrieval.yml >> /etc/ansible/ansible_malware_retrieval.yml

# Create python host retrieval
cat $cloudsDir/server/ansible/ansible_get_hosts.py >> /etc/ansible/ansible_get_hosts.py
chmod +x /etc/ansible/ansible_get_hosts.py

chown cloudsofhoney:cloudsofhoney /etc/ansible/ansible_malware_retrieval.yml
chown cloudsofhoney:cloudsofhoney /etc/ansible/ansible_get_hosts.py

# retrieve malware every 24 hour
echo "00 00 * * * cloudsofhoney /usr/bin/ansible-playbook /etc/ansible/malware_retrieval.yml -i /etc/ansible/ansible_get_hosts.py > /home/cloudsofhoney/cron.output" >> /etc/crontab

# Make sure cron starts at boot
systemctl enable crond
systemctl start crond
