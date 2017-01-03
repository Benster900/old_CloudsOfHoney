#!/bin/bash

set -x
set -e

# Install ansible
yum install ansible -y

# Create user
useradd cloudsofhoney

# generate ssh private and public key
su - cloudsofhoney -c 'ssh-keygen -t rsa -q -P ""'
