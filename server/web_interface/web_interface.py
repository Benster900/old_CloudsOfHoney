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
		path = os.path.abspath(os.path.join(MHN_SCRIPTS_SERVER_HOME, scriptName))
		try:
			data = open(path,'r').read()
		except IOError:
			data = "File does not exist"
		return data

"""
"""
@app.route('/deploy/newsensor/<string:token>', methods=['GET','POST'])
def newSensor():
	
	return

"""
Deploy menu tab to select script to deploy new network sensor or honeypot
"""
@app.route('/deploy', methods=['GET','POST'])
def deploy():
	import os
	deployScripts = []
	deployCommand = ""
	fileContents = ""
	scriptRequest = ""

	if request.method == 'POST':
		scriptRequest = request.form['scriptSelect']
		# If the drop down menu is not create a new script get selected scripts contents
		if scriptRequest != "newScript":
			fileContents = open(os.path.abspath(os.path.join(MHN_SCRIPTS_SERVER_HOME, scriptRequest))).read()
			deployCommand = "wget https://{0}/scripts/{1}".format(MHN_DOMAIN_NAME, scriptRequest)


	for file in os.listdir(MHN_SCRIPTS_SERVER_HOME):
		if 'deploy' in file:
			deployScripts.append(file)

	#data = open(fileLoc)
	return render_template('deploy.html', deployScripts=deployScripts, deployCommand=deployCommand, fileContents=fileContents, scriptRequest=scriptRequest )

@app.route('/sensors')
def sensors():
	r.connect( "172.16.0.161", 28015).repl()
	cursor = r.table("Sensors").run()
	test=list(cursor)

	return render_template('sensors.html', sensors=test)

# Send user to kibana interface to query data
@app.route('/kibana')
def kibana():
    return redirect("http://localhost:5601", code=302)

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/about')
def about():
    return render_template('about.html')

#Run the app :)
if __name__ == "__main__":
    app.run(debug = True, host='127.0.0.1',port=5000)
