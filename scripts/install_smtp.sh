#!/bin/bash

set -x
set -e

read -p "Setup E-mail alerts [Y/N]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then

yum remove sendmail -y
yum install postfix -y
yum install -y mailx

echo "virtual_alias_domains = $domainName
virtual_alias_maps = hash:/etc/postfix/virtual" >> /etc/postfix/main.cf

read -p "Enter e-mail to forward all alerts to: " -e mail
echo "@$domainName $email" >> /etc/postfix/virtual

echo "Send test e-mail"
echo "Testing $domainName e-mail service" | mail -s "Message Subject" root@$domainName

sudo postmap /etc/postfix/virtual
systemctl enable postfix
systemctl start postfix
fi
