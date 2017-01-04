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
@app.route('/scripts/<string:scriptID>/<string:scriptName>', methods = ['GET'])
def script(scriptID, scriptName):
	if request.method == 'GET':
		# connect to database
		r.connect( "127.0.0.1", 28015).repl()
		cursor = r.db("cloudsofhoney").table("scripts").run()

		# Get script contents
		scriptContents = r.db("cloudsofhoney").table("scripts").get(scriptID).run()['scriptContents']
		return scriptContents

"""
Add new sensor to database
"""
@app.route('/newsensor/<string:honeypotHostname>/<string:honeypoyTokenID>', methods=['GET','POST'])
def newSensor(honeypotHostname, honeypoyTokenID):
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
		    tokenID = honeypoyTokenID
       
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
def deploy():
	deployScripts = []
	deployCommand = ""
	scriptRequest = ""
	scriptContents = ""

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

		deployCommand = "wget https://{0}/scripts/{2}/{1}".format(MHN_DOMAIN_NAME, scriptRequest, scriptUID )
	    else:
		if "deploy_" not in request.form['scriptName']:
		    deployCommand = 'Start script name with "deploy_"'
		    scriptRequest = 'newScript'
		    scriptContents = request.form['scriptBox']
		else:
		    scriptName = request.form['scriptName']
		    scriptContents = request.form['scriptBox']
		    sensorType = str(scriptName[scriptName.find('_')+1:-3])
		    r.db("cloudsofhoney").table("scripts").insert({'scriptName':scriptName, 'sensorType': '', 'scriptContents':scriptContents }).run()
		    
		    scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptName).run())[0]
		    scriptUID = scriptEntry['id']
		    scriptContents = scriptEntry['scriptContents']

		    deployCommand = "wget https://{0}/scripts/{2}/{1}".format(MHN_DOMAIN_NAME, scriptRequest, scriptUID )
	# Get all deploy scripts
	for doc in cursor:
	    if 'deploy_' in doc['scriptName']:
        	deployScripts.append(doc['scriptName'])

	#data = open(fileLoc)
	return render_template('deploy.html', deployScripts=deployScripts, deployCommand=deployCommand, fileContents=scriptContents, scriptRequest=scriptRequest )

"""
Returns a list of honeypots and network sensors deployed.
"""
@app.route('/sensors')
def sensors():
	r.connect( "127.0.0.1", 28015).repl()
	cursor = list(r.db('cloudsofhoney').table("sensors").run())

	return render_template('sensors.html', sensors=cursor)

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
if __name__ == "__main__":
    app.run(debug = True, host='0.0.0.0',port=5000)
