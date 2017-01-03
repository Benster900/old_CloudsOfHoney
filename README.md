# CloudsOfHoneyManagementNode
I have always been a fan of the Modern Honey Network project but I always felt it lacked certain features. This is a fun project to develop my own honeypot network using MHN as a template. The big differences between my system and theres is an ELK backend, MariaDB backend, Logstash instead of hpfeeds, and malware retrieval and statistics. I mean no disrespect to the creators of the MHN project.


## ELK stack
### Logstash


### Elasticsearch


### Kibana

### Filebeat


### Elastalert

## Ansible
Mechanism used to connect to all honeypots and retrieve data. This system is very simplistic cause honeypots only need the ssh pub_key.

## RethinkDB
A neat new NoSQL database that I am tinkering with.

## Malware Database


## Malware Partition
A seperate partition is created on the system with the execution permissions turned off.

### Rclone
My university has Google Apps so I get "unlimited" Google Drive space. I decided to store all my samples on Google Drive rather than pay for Amazon S3.

# Adding a new honeypot
### Adding a new honeypot or network sensor is relatively simple.
1. First create a deploy script named "deploy_<honeypot/sensor>.sh"
   a. The naming convention is import to import the new script into the database.
2. Second create a Logstash filter to ingest data.
3. Third add any data directories to Ansible to have data retrieved.
4. Lastly, create a Filebeat input on the honeypot and copy the ssh pub key.

## System Requirements
OS: CentOS 7 64-bit
CPU: 2 cores
Ram: 4GB
HDD: 40GB

# Thanks to:
#### MHN Project
MHN Project: https://github.com/threatstream/mhn

#### Web Theme
Bootstrap Theme Link: https://startbootstrap.com/template-overviews/sb-admin-2/
Github Code Link: https://github.com/poormonfared/sb-admin2
