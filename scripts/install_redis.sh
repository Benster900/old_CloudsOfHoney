#!/bin/bash

set -x
set -e

################################## Install/Setup Redis ##################################
yum install redis -y

systemctl enable redis
systemctl start redis
