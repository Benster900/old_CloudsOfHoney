#!/bin/bash

set -x
set -e

read -p "Setup E-mail alerts [Y/N]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then

yum remove sendmail -y
yum install postfix -y

echo "virtual_alias_domains = $domainName
virtual_alias_maps = hash:/etc/postfix/virtual" >> /etc/postfix/main.cf

ead -p "Enter e-mail to forward all alerts to: " -e mail
echo "@$domainName $email" >> /etc/postfix/virtual

systemctl enable postfix
systemctl start postfix
fi
