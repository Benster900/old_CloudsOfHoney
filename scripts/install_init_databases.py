#!/usr/bin/env python
import rethinkdb as r
import argparse
import os
import sys
import time

def main():
    MHN_SCRIPTS_SERVER_HOME = sys.argv[1]
    print MHN_SCRIPTS_SERVER_HOME

    # wait for database to start
    time.sleep(10)

    # Connect to rethinkdb
    r.connect(host="localhost", port=28015).repl()	

    # Create database
    r.db_create("cloudsofhoney").run()

    # Create tables
    r.db("cloudsofhoney").table_create("scripts").run()
    r.db("cloudsofhoney").table_create("sensors").run()
    r.db("cloudsofhoney").table_create("malwareSamples").run()

    # Setup scrits table
    for filename in os.listdir(MHN_SCRIPTS_SERVER_HOME):
	if 'deploy' in filename:
	    scriptContents = str(open(filename, 'r').read())
	    fileName=str(filename)
            sensorType=str(filename[filename.find('_')+1:-3])		
	    print fileName
 	    r.db('cloudsofhoney').table("scripts").insert({"scriptName": fileName ,"sensorType": sensorType, "scriptContents": scriptContents}).run()
main()
