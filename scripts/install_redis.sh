#!/bin/bash

set -x
set -e

<<<<<<< HEAD
################################## Install/Setup Redis ##################################
=======
################################## Install/Setup redis ##################################
>>>>>>> temp
yum install redis -y

systemctl enable redis
systemctl start redis
