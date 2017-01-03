#!/usr/bin/env python
import rethinkdb as r
import os
import sys


def main():
    MHN_SCRIPTS_SERVER_HOME = sys.argv[1]
    print MHN_SCRIPTS_SERVER_HOME

    # Connect to rethinkdb
    r.connect(host="localhost", port=28015).repl()

    # Create database
    r.db_create("cloudsofhoney").run()

    # Create tables
    r.db("cloudsofhoney").table_create("scripts").run()
    r.db("cloudsofhoney").table_create("sensors").run()
    r.db("cloudsofhoney").table_create("malwareSamples").run()

    # Setup scrits table
    for file in os.listdir(MHN_SCRIPTS_SERVER_HOME):
        if 'deploy' in file:
            fileName=str(file)
            sensorType=str(file[file.find('_')+1:-3])
            print fileName
            print sensorType
            r.db('cloudsofhoney').table("scripts").insert({"scriptName": fileName ,"sensorType": sensorType}).run()
main()
