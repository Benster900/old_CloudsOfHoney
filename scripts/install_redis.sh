#!/bin/bash

set -x
set -e

################################## Install/Setup redis ##################################
yum install redis -y

systemctl enable redis
systemctl start redis
