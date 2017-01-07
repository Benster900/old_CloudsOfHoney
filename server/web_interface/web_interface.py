"""
Author: Ben Bornholm
Date: 1-1-17
Description: Web interface for CloudsOfHoney
"""

# We need to import request to access the details of the POST request
# and render_template, to render our templates (form and response)
# we'll use url_for to get some URLs for the app on the templates
from flask import Flask, render_template, redirect, request, url_for
from flask_bootstrap import Bootstrap
from rethinkdb.errors import *
import rethinkdb as r
from config import *

# Initialize the Flask application
app = Flask(__name__)
Bootstrap(app)



# Define a route for the default URL, which loads the form
@app.route('/')
def homepage():
	return render_template('homepage.html')

"""
Allows curl and wget to retireve scripts
"""
@app.route('/script/<string:scriptName>', methods = ['GET'])
def script(scriptName):
	if request.method == 'GET':
		# connect to database
		r.connect( "127.0.0.1", 28015).repl()
		cursor = r.db("cloudsofhoney").table("scripts").run()

		# Get script contents
		scriptContents = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptRequest).run())[0]['scriptContents']

		return scriptContents

"""
Add new sensor to database
"""
@app.route('/deploy/newsensor/<string:script> <string:tokenID> ', methods=['GET','POST'])
def newSensor(script,tokenID):
	if request.method == 'GET':
		# connect to database
		r.connect( "127.0.0.1", 28015).repl()
		cursor = r.db("cloudsofhoney").table("scripts").run()

		ipAddr = request.remote_addr
		hostname = ''
		sensorType = ''

		# Add new entry to sensor table
		r.db("cloudsofhoney").table("sensors").insert({"name":hostname, "hostname":hostname, "ipaddr":ipAddr, "sensorType":sensorType, "attacks":0})

		# Get sensor UID
		sensorID = list(r.db("cloudsofhoney").table("sensors").filter({r.row["hostname"] == 'hostname', r.row["ipaddr"] == 'ipAddr', r.row["sensorType"] == 'sensorType' }).run())[0]['id']

	return sensorID

"""
Deploy menu tab to select script to deploy new network sensor or honeypot
"""
@app.route('/deploy', methods=['GET','POST'])
def deploy():
	deployScripts = []
	deployCommand = ""
	fileContents = ""
	scriptRequest = ""

	# connect to database
	r.connect( "127.0.0.1", 28015).repl()
	cursor = r.db("cloudsofhoney").table("scripts").run()

	# If web request is pushing data to the server
	if request.method == 'POST':
		# Get the script being requested
		scriptRequest = request.form['scriptSelect']
		# If the drop down menu is not create a new script get selected scripts contents
		if scriptRequest != "newScript":
			scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptRequest).run())[0]

			scriptContents = scriptEntry['scriptContents']
			scriptUID = scriptEntry['id']

			deployCommand = "wget https://{0}/scripts/{1} {2}".format(MHN_DOMAIN_NAME, scriptRequest, scriptUID )
		else:
			scriptName = request.form['scriptName']
			if 'deploy_' not in scriptName:
				flash('Please include "deploy_" in script name for honeypot or network sensor')
			else:
				flash("Added script to database")


	# Get all deploy scripts
	for doc in cursor:
		if 'deploy_' in doc['scriptName']:
        	deployScripts.append(doc['scriptName'])

	#data = open(fileLoc)
	return render_template('deploy.html', deployScripts=deployScripts, deployCommand=deployCommand, fileContents=fileContents, scriptRequest=scriptRequest )

"""
Returns a list of honeypots and network sensors deployed.
"""
@app.route('/sensors')
def sensors():
	r.connect( "172.16.0.161", 28015).repl()
	cursor = r.table("Sensors").run()
	test=list(cursor)

	return render_template('sensors.html', sensors=test)

# Send user to kibana interface to query data
@app.route('/kibana')
def kibana():
    return redirect("https://localhost:9000", code=302)

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/about')
def about():
    return render_template('about.html')

#Run the app :)
#if __name__ == "__main__":
#    app.run(debug = True, host='127.0.0.1',port=5000)
