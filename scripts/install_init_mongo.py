#!/usr/bin/env python
from pymongo import MongoClient
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
    p = MongoClient()

    # Create database
    db = p['cloudsofhoney']

    # Setup scrits table
    for filename in os.listdir(MHN_SCRIPTS_SERVER_HOME):
	if 'deploy' in filename:
	    scriptContents = str(open(filename, 'r').read())
	    fileName=str(filename)
            sensorType=str(filename[filename.find('_')+1:-3])		
	    print fileName
	    db.scripts.insert_one({"scriptName": fileName ,"sensorType": sensorType, "scriptContents": scriptContents})
main()
