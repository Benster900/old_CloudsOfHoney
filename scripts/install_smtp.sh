#!/bin/bash

set -x
set -e

# Installing postfix
yum remove sendmail -y
yum install postfix -y
yum install -y mailx

if [[ $emailAlerts =~ ^[Yy]$ ]]; then
# Configure postfix to forward mails
echo "virtual_alias_domains = $domainName
virtual_alias_maps = hash:/etc/postfix/virtual" >> /etc/postfix/main.cf

# emails you want to forward 
read -p "Enter e-mail to forward all alerts to: " -e email
echo "@$domainName $emailAddress" >> /etc/postfix/virtual

# Update the postfix lookup table 
postmap /etc/postfix/virtual

# Sending test e-mail
echo "Send test e-mail"
echo "Testing $domainName e-mail service" | mail -s "CloudsOfHoney Testing SMTP Server" root@$domainName

#sudo postmap /etc/postfix/virtual
systemctl enable postfix
systemctl start postfix
fi
