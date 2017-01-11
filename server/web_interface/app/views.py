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
from flask_security import Security, SQLAlchemyUserDatastore, UserMixin, RoleMixin, login_required
from flask_bootstrap import Bootstrap
from flask_mail import Mail
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.exc import IntegrityError, InvalidRequestError
from sqlalchemy.orm import sessionmaker
from sqlalchemy import * 
from rethinkdb.errors import *
import rethinkdb as r
from config import SECRET_KEY
from datetime import datetime

from app import app
from app import db
from app import mail
from app import bootstrap
from app import login_manager
from app import security
from .models import user_datastore, User, Role

# Initialize the Flask application
#bootstrap.init_app(app)
#mail.init_app(app)
#db.init_app(app)
#security.init_app(app, user_datastore)
#login_manager.init_app(app)

#app = Flask(__name__)
#app.config.from_object('config')
#app.config['SECURITY_REGISTERABLE'] = True
#Bootstrap(app)

# Initialze an instance of LoginManager
#login_manager = LoginManager()
#login_manager.init_app(app)

# Create mail object
#mail = Mail(app)

# Create database connection object
#db = SQLAlchemy(app)

# Define models
#roles_users = db.Table('roles_users',
#        db.Column('user_id', db.Integer(), db.ForeignKey('user.id')),
#        db.Column('role_id', db.Integer(), db.ForeignKey('role.id')))
#
#class Role(db.Model, RoleMixin):
#    id = db.Column(db.Integer(), primary_key=True)
#    name = db.Column(db.String(80), unique=True)
#    description = db.Column(db.String(255))
#
#class User(db.Model, UserMixin):
#    id = db.Column(db.Integer, primary_key=True)
#    email = db.Column(db.String(255), unique=True)
#    password = db.Column(db.String(255))
#    active = db.Column(db.Boolean())
#    confirmed_at = db.Column(db.DateTime())
#    last_login_at = db.Column(db.DateTime())
#    current_login_at = db.Column(db.DateTime())
#    last_login_ip = db.Column(db.String(45))
#    current_login_ip = db.Column(db.String(45))
#    login_count = db.Column(db.Integer()) 
#    roles = db.relationship('Role', secondary=roles_users, backref=db.backref('users', lazy='dynamic'))

# Setup Flask-Security
#user_datastore = SQLAlchemyUserDatastore(db, User, Role)
#security = Security(app, user_datastore)


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
@login_required
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
@app.route('/newsensor/<string:honeypotHostname>/<string:scriptID>', methods=['GET','POST'])
@login_required
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

	# connect to database
	r.connect( "127.0.0.1", 28015).repl()

	# If web request is pushing data to the server
	if request.method == 'POST':
	    # Get the script being requested
	    scriptRequest = request.form['scriptSelect']
	    
	    # Selected scripts contents
	    if scriptRequest != "newScript" and ( "submit_name" not in request.form ):
	        scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptRequest).run())[0]
		scriptContents = scriptEntry['scriptContents']
		scriptUID = scriptEntry['id']
		deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1} && sudo bash {1} {0} {2}""".format(MHN_DOMAIN_NAME, scriptRequest, scriptUID )
	    # Update existing script 
	    elif scriptRequest != "newScript" and ( "submit_name" in request.form ):
		scriptContents = request.form['scriptBox']
		r.db("cloudsofhoney").table("scripts").filter({"scriptName": scriptRequest}).update({"scriptContents": scriptContents}).run()	   

		#
		scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptRequest).run())[0]
		scriptContents = scriptEntry['scriptContents']
		scriptUID = scriptEntry['id']
                deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1} && sudo bash {1} {0} {2}""".format(MHN_DOMAIN_NAME, scriptRequest, scriptUID )
 
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
                    r.db("cloudsofhoney").table("scripts").insert({'scriptName':scriptName, 'sensorType': sensorType, 'scriptContents':scriptContents }).run()

                    # Get information for deploy command
                    scriptEntry = list(r.db("cloudsofhoney").table("scripts").filter(r.row["scriptName"] == scriptName).run())[0]
                    scriptUID = scriptEntry['id']
                    scriptContents = scriptEntry['scriptContents']

                    deployCommand = r"""wget https://{0}/scripts/{2}/{1} -O {1} && sed -i -e 's/\r$//' {1}  && sudo bash {1} {0} {2}""".format(MHN_DOMAIN_NAME, scriptName, scriptUID )
	    # Select new script but DO NOT create a script without content
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
def settings():
    return render_template('settings.html')

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/about')
def about():
    return render_template('about.html')

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

#Run the app :)
#if __name__ == "__main__":
#    app.run(debug = True, host='0.0.0.0',port=5000)
