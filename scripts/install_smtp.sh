#!/bin/bash

set -x
set -e
yum remove sendmail -y
yum install postfix -y

sed -i "s/#mydomain = domain.tld/mydomain = $domainName /g" /etc/postfix/main.cf
sed -i 's/#myorigin = $mydomain/myorigin = $mydomain/g' /etc/postfix/main.cf

systemctl enable postfix
systemctl start postfix
