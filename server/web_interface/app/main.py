"""
Author: Ben Bornholm
Date: 1-1-17
Description: Web interface for CloudsOfHoney
"""

# We need to import request to access the details of the POST request
# and render_template, to render our templates (form and response)
# we'll use url_for to get some URLs for the app on the templates
from flask import Flask, render_template, redirect, request, url_for, flash, g
from flask_login import LoginManager, login_user , logout_user , current_user , login_required
from config import COH_DOMAIN_NAME
from datetime import datetime
from rethinkdb.errors import *
import rethinkdb as r

from .models import user_datastore, User, Role
from app import app
from app import db
from app import mail
from app import bootstrap
from app import login_manager
from app import security
from app import mongo

# Define a route for the default URL, which loads the form
@app.route('/')
@app.route('/homepage')
@login_required
def homepage():
    return render_template('homepage.html')

"""
Retrieve public SSH key from local machine
"""
@app.route('/sshkeyauthentication/<string:sensorID>', methods = ['GET'])
def sshkeyauthentication(sensorID):
	if request.method == 'GET':
		# connect to database
		r.connect( "127.0.0.1", 28015).repl()
 
		if r.db("cloudsofhoney").table("sensors").get(sensorID).run():
			import os
			sshkey = open('/home/cloudsofhoney/.ssh/id_rsa.pub','r').read()
			return sshkey

		return "Not a valid known sensor please register sensor."

"""
Allows curl and wget to retireve scripts
"""
@app.route('/scripts/<string:scriptID>/<string:scriptName>', methods = ['GET'])
def script(scriptID, scriptName):
	
	print "hello"
	print scriptID
	print scriptName
	print "hello"
	
	if request.method == 'GET':
		# connect to database
		r.connect( "127.0.0.1", 28015).repl()
		cursor = r.db("cloudsofhoney").table("scripts").run()

		# Get script contents
		scriptContents = r.db("cloudsofhoney").table("scripts").get(scriptID).run()['scriptContents']
		print scriptContents
		return scriptContents

"""
Add new sensor to database
"""
@app.route('/newsensor/<string:honeypotHostname>/<string:scriptID>', methods=['GET','POST'])
def newSensor(honeypotHostname, scriptID):
	ipAddr = None
	hostname = None
	sensorType = None
	tokenID = None

        if request.method == 'POST':
                    # connect to database
	            r.connect( "127.0.0.1", 28015).repl()
	            cursor = r.db("cloudsofhoney").table("scripts").run()

	            # Get new sensor identity
	            ipAddr = request.remote_addr
		    hostname = honeypotHostname
		    tokenID = scriptID

                    # Check all data is valid before adding
	            if (ipAddr != None and hostname != None and tokenID != None):
			sensorType = r.db("cloudsofhoney").table("scripts").get(tokenID).run()['sensorType']

        		# Add new entry to sensor table and get sensor ID
                        sensorID = r.db("cloudsofhoney").table("sensors").insert({"name":hostname, "hostname":hostname, "ipaddr":ipAddr, "sensorType":sensorType, "attacks":0}).run()['generated_keys'][0]
	                return sensorID

        return "Honeypot not regisitered bad data\nIP Address: {0}\nHostname: {1}\nSensor Type: {2}\n\n".format(ipAddr, hostname, sensorType)

"""
Deploy menu tab to select script to deploy new network sensor or honeypot
"""
@app.route('/deploy', methods=['GET','POST'])
@login_required
def deploy():
	deployScripts = []
	deployCommand = ""
	scriptRequest = ""
	scriptContents = ""

	# If web request is pushing data to the server
	if request.method == 'POST':
	    # Get the script being requested
	    scriptRequest = request.form['scriptSelect']

	    # Selected scripts contents
	    if scriptRequest != "newScript" and ( "submit_name" not in request.form ):
	        scriptEntry = list(mongo.db.scripts.find({"scriptName" : scriptRequest}))[0]
		scriptContents = scriptEntry['scriptContents']
		scriptUID = scriptEntry['_id']
		deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1} && sudo bash {1} {0} {2}""".format(request.headers['Host'], scriptRequest, scriptUID )
	    # Update existing script 
	    elif scriptRequest != "newScript" and ( "submit_name" in request.form ):
		scriptContents = request.form['scriptBox']	
		print scriptRequest
		print scriptContents
		# Update WITHOUT $set will replace the entire document
		mongo.db.scripts.update({"scriptName": scriptRequest}, {"$set": {"scriptContents": scriptContents}})
		
		scriptEntry = list(mongo.db.scripts.find({"scriptName" :scriptRequest}))[0]
		print scriptEntry
		scriptContents = scriptEntry['scriptContents']
		scriptUID = scriptEntry['_id']
                deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1} && sudo bash {1} {0} {2}""".format(request.headers['Host'], scriptRequest, scriptUID )
 
	    # Create new script
	    elif scriptRequest == "newScript" and ( "submit_name" in request.form):
	    	if "deploy_" not in request.form['scriptName']:
                    deployCommand = 'Start script name with "deploy_"'
                    scriptRequest = "newScript"
                    scriptContents = request.form['scriptBox']
		else:
                    # Insert script into database
                    scriptName = request.form['scriptName']
                    scriptRequest = scriptName
                    scriptContents = request.form['scriptBox']
                    sensorType = scriptName[scriptName.find('_')+1:-3]
		    mongo.db.scripts.insert({'scriptName': scriptName, 'sensorType': sensorType, 'scriptContents': scriptContents })

                    # Get information for deploy command
                    scriptEntry = list(mongo.db.scripts.find({"scriptName" : scriptName}))[0]
                    scriptUID = scriptEntry['_id']
                    scriptContents = scriptEntry['scriptContents']

                    deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1}  && sudo bash {1} {0} {2}""".format(COH_DOMAIN_NAME, scriptName, scriptUID )
	    # Select new script but DO NOT create a script without content
	    elif scriptRequest == "newScript" and ( "submit_name" not in request.form ):
		deployCommand = ""
        	scriptRequest = "newScript"
        	scriptContents = ""

	# Get all deploy scriptsi
	cursor = mongo.db.scripts.find({})
	for doc in cursor:
	    if 'deploy_' in doc['scriptName']:
        	deployScripts.append(doc['scriptName'])

	return render_template('deploy.html',deployScripts=deployScripts, deployCommand=deployCommand, fileContents=scriptContents, scriptRequest=scriptRequest )

"""
Returns a list of honeypots and network sensors deployed.
"""
@app.route('/sensors')
@login_required
def sensors():
	r.connect( "127.0.0.1", 28015).repl()
	cursor = list(r.db('cloudsofhoney').table("sensors").run())

	return render_template('sensors.html', sensors=cursor)

# Send user to kibana interface to query data
@app.route('/kibana')
@login_required
def kibana():
    return redirect("https://{0}:9000".format(request.host), code=302)

@app.route('/search')
@login_required
def search():
    return render_template('search.html')

@app.route('/settings')
@login_required
def settings():
    return render_template('settings.html')

"""
Incident Respnse Dashboard
"""
@app.route('/ir/dashboard')
@login_required
def irDashboard():
    return render_template('ir/dashboard.html')

@app.route('/ir/createEvent')
@login_required
def irCreateEvent():
    return render_template('ir/createEvent.html')

"""
Logout authenticated user
"""
@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))
 
@login_manager.unauthorized_handler
def handle_needs_login():
    flash("You have to be logged in to access this page.")
    return redirect(url_for('security.login', next=request.endpoint))

"""
pull user info from the database based on session id
"""
@app.before_request
def before_request():
    g.user = current_user


@login_manager.user_loader
def user_loader(user_id):
    """Given *user_id*, return the associated User object.

    :param unicode user_id: user_id (email) user to retrieve
    """
    return db.session.query(User).get(user_id)

# Create a user to test with
@app.before_first_request
def setup():
    db.create_all()
