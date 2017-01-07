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
<<<<<<< HEAD
		scriptContents = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptRequest).run())[0]['scriptContents']

=======
		scriptContents = r.db("cloudsofhoney").table("scripts").get(scriptID).run()['scriptContents']
>>>>>>> 46d864fd69d0cae37d5a36dbf922f76e6855ea7e
		return scriptContents

"""
Add new sensor to database
"""
<<<<<<< HEAD
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
=======
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
>>>>>>> 46d864fd69d0cae37d5a36dbf922f76e6855ea7e

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
<<<<<<< HEAD
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
=======
>>>>>>> 46d864fd69d0cae37d5a36dbf922f76e6855ea7e

	# If web request is pushing data to the server
	if request.method == 'POST':
	    # Get the script being requested
	    scriptRequest = request.form['scriptSelect']
	    
	    # Create new scritp
	    # Create a new script get selected scripts contents
	    # Selected scripts contents
	    if scriptRequest != "newScript":
	        scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptRequest).run())[0]
		scriptContents = scriptEntry['scriptContents']
		scriptUID = scriptEntry['id']
		deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1} && sudo bash {1} {0} {2}""".format(MHN_DOMAIN_NAME, scriptRequest, scriptUID )
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
                    r.db("cloudsofhoney").table("scripts").insert({'scriptName':scriptName, 'sensorType': sensorType, 'scriptContents':scriptContents }).run()

                    # Get information for deploy command
                    scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptName).run())[0]
                    scriptUID = scriptEntry['id']
                    scriptContents = scriptEntry['scriptContents']

                    deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1}  && sudo bash {1} {0} {2}""".format(MHN_DOMAIN_NAME, scriptName, scriptUID )
	    elif scriptRequest == "newScript" and ( "submit_name" not in request.form ):
		deployCommand = ""
        	scriptRequest = "newScript"
        	scriptContents = ""

	# Get all deploy scripts
	cursor = r.db("cloudsofhoney").table("scripts").run()
	for doc in cursor:
	    if 'deploy_' in doc['scriptName']:
        	deployScripts.append(doc['scriptName'])

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

@app.route('/search')
def search():
    return render_template('search.html')

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/about')
def about():
    return render_template('about.html')

#Run the app :)
if __name__ == "__main__":
    app.run(debug = True, host='0.0.0.0',port=5000)
