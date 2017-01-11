# CloudsOfHoneyManagementNode
I have always been a fan of the Modern Honey Network project but I always felt it lacked certain features. This is a fun project to develop my own honeypot network using MHN as a template. The big differences between my system and theres is an ELK backend, MariaDB backend, Logstash instead of hpfeeds, and malware retrieval and statistics. I mean no disrespect to the creators of the MHN project.

# Installation
`git clone https://github.com/Benster900/CloudsOfHoneyManagementNode.git /opt/CloudsOfHoneyManagementNode`

`cd /opt/CloudsOfHoneyManagementNode`

`./setupScript`

## ELK stack
### Logstash


### Elasticsearch


### Kibana
#### Indexes
`Network Sensor - p0f : p0f-filebeat--%{+YYYY.MM.dd}
Network Sensor - Bro: bro-filebeat--%{+YYYY.MM.dd}
Network Sensor - Snort: snort-filebeat--%{+YYYY.MM.dd}
Honeypot - Cowire: cowire-filebeat--%{+YYYY.MM.dd}
Honeypot - Elastichoney: elastichoney-filebeat--%{+YYYY.MM.dd}
`

### Filebeat


### Elastalert



## Ansible
### SSH Keys
These keys can be updated as needed because the Flask app will read the ssh pub key from disk. However all honeypots need the new pub key.

`Location: /home/cloudsofhoney/.ssh/[id_rsa.pub, id_rsa]`

### crontab
Mechanism used to connect to all honeypots and retrieve data. This system is very simplistic cause honeypots only need the ssh pub_key.
Ansible currently runs every 24 hours to retrieve malware from honeypots. The -i flag runs a python script which pulls down all sensor IP addresses from the RethinkDB database. It then runs the retrieval script "malware_retrieval.yml" on each sensor.

`00 00 * * * cloudsofhoney /usr/bin/ansible-playbook /etc/ansible/ansible_malware_retrieval.yml -i /etc/ansible/ansible_get_hosts.py > /home/cloudsofhoney/cron.output`


## RethinkDB
A neat new NoSQL database that I am tinkering with.

## Malware Database
### Local Malware
Ansible is used to retrieve malware from each sensor and store it locally for 24 hours. Within this 24 hour window the malware is processes by a binary analyzer.
`Location: /srv/malwareSamples/<date>`


## Malware Partition
A seperate partition is created on the system with the execution permissions turned off.

### Rclone
My university has Google Apps so I get "unlimited" Google Drive space. I decided to store all my samples on Google Drive rather than pay for Amazon S3.


# Alerts
## SMTP Alerts


## Elastalert



## Honeypots
### Cowire
### Elastichoney

## Network Sensors
### p0f


### Bro Network Security Monitor


### Snort Network IDS/IPS
service: snort is the actual NIDS for the local system.
service: snortLogging uses u2json to convert unified2 to json.




# Adding a new honeypot
### Adding a new honeypot or network sensor is relatively simple.
1. Create a deploy script named "deploy_<honeypot/sensor>.sh"
   a. The naming convention is import to import the new script into the database.
2. Create a Logstash filter to ingest data.
3. Add any data directories to Ansible to have data retrieved.
4. Create a Filebeat input on the honeypot and copy the ssh pub key.

## System Requirements
* OS: CentOS 7 64-bit
* CPU: 2 cores
* Ram: 4GB
* HDD: 40GB


# Thanks to:
#### MHN Project
MHN Project: https://github.com/threatstream/mhn
