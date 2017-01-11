#!./app/env/bin/python
"""
#dbUser
#dbPass
#dbHost
#dbDatabase
#SECRET_KEY
#SECURITY_PASSWORD_HASH
#SECURITY_PASSWORD_SALT
"""
import os
import uuid
import random, string
from argparse import ArgumentParser

def main():
	p = ArgumentParser()
    	p.add_argument('--dbUser', '-u', action='store', help='Username for database', default='clouduser')
    	p.add_argument('--dbPass', '-p', action='store', help='the address to bind to', default='password123')
    	p.add_argument('--dbHost', '-a', action='store', help='IP address of database', default='localhost')
    	p.add_argument('--dbDatabase', '-d', action='store', help='Database to connect to', default='cloudsofhoney')
    	p.add_argument('--dbHash', '-k', action='store', help='Hashing algorithm to use on database: plaintext, bcrypt or pbkdf2_sha256', default='pbkdf2_sha256')
    	args = p.parse_args()

	# Open file	
	varFile = open(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'app.vars'),'w')
	varFile.write(args.dbUser+'\n')
	varFile.write(args.dbPass+'\n')
	varFile.write(args.dbHost+'\n')
	varFile.write(args.dbDatabase+'\n')
	varFile.write(str(uuid.uuid4())+'\n')
	varFile.write(args.dbHash+'\n')
	varFile.write(''.join(random.choice(string.lowercase + string.uppercase + string.digits) for i in range(10)) + '\n')

main()
