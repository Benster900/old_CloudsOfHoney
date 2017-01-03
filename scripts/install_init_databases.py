#!/usr/bin/env python
import rethinkdb as r
import os
import sys


def main():
    MHN_SCRIPTS_SERVER_HOME = sys.argv[1]
    # Connect to rethinkdb
    r.connect( "localhost", 28015).repl()

    # Create database
    r.db_create("cloudsofhoney")

    # Create tables
    r.db("cloudsofhoney").table_create("scripts").run()
    r.db("cloudsofhoney").table_create("sensors").run()
    r.db("cloudsofhoney").table_create("malwareSamples").run()

    # Setup scrits table
    for file in os.listdir(MHN_SCRIPTS_SERVER_HOME)
        if 'deploy' in file:
            r.table("scripts").insert({'scriptName':'{0}','sensorType':'{1}'}).format(file,file[file.find('_')+1:-3])

main()
