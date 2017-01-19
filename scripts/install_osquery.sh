#!/bin/bash

set -x
set -e

################################## Install/Setup OSquery ##################################
sudo rpm -ivh https://osquery-packages.s3.amazonaws.com/centos7/noarch/osquery-s3-centos7-repo-1-0.0.noarch.rp
sudo yum install osquery

systemctl enable osqueryctl
systemctl start osqueryctl
