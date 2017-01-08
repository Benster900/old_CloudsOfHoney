#!/usr/bin/env python
import rethinkdb as r

def main():
        hostDict = {}

        # Connect to database
        r.connect( "127.0.0.1", 28015).repl()

        # Get sensor ip address
        ipLst =  [ item['ipaddr'] for item in r.db("cloudsofhoney").table("sensors").run()]
        ipLst.append('172.16.0.197')
        hostDict = {"hosts":ipLst}
        json_dict = {"honeypots":hostDict}

        print json_dict
main()
