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
from flask_bootstrap import Bootstrap
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.exc import IntegrityError, InvalidRequestError
from sqlalchemy.orm import sessionmaker
from sqlalchemy import * 
from rethinkdb.errors import *
import rethinkdb as r
from config import SECRET_KEY
#from models import User 
from datetime import datetime


# Initialize the Flask application
app = Flask(__name__)
app.config.from_object('config')
Bootstrap(app)

# Initialze an instance of LoginManager
login_manager = LoginManager()
login_manager.init_app(app)

# Initializa database connection for flask app
engine = create_engine(app.config['SQLALCHEMY_DATABASE_URI'])
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column('user_id',Integer , primary_key=True)
    username = Column('username', String(20), unique=True , index=True)
    password = Column('password' , String(255))
    email = Column('email',String(50),unique=True , index=True)
    registered_on = Column('registered_on' , DateTime)

    def __init__(self , username ,password , email):
        self.username = username
        self.password = password
        self.email = email
        self.registered_on = datetime.utcnow()

    def is_authenticated(self):
        return True

    def is_active(self):
        return True

    def is_anonymous(self):
        return False

    def get_id(self):
        return unicode(self.id)

    def __repr__(self):
        return '<User %r>' % (self.username)

Base.metadata.create_all(engine)
Session = sessionmaker(bind=engine)
session = Session()


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
Login is user based off user input
"""
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
    	# First time admin setup and check database has no users
    	if session.query(User).first() == None:
        	return redirect(url_for('setup'))
        return render_template('login.html')

    username = request.form['username']
    password = request.form['password']
    remember_me = False
    if 'remember_me' in request.form:
        remember_me = True
    registered_user = session.query(User).filter(User.username==username, User.password==password).first()

    if registered_user is None:
        return redirect(url_for('login'))
    login_user(registered_user, remember = remember_me)
    return redirect(request.args.get('next') or url_for('deploy'))

"""
Setup
"""
@app.route('/setup' , methods=['GET','POST'])
def setup():
    if session.query(User).first() == None:
    	if request.method == 'GET':
    		return render_template('setup.html')
    user = User(username=request.form['username'], password=request.form['password'], email=request.form['email'])
    session.add(user)
    session.commit()
    flash('User successfully registered')
    return redirect(url_for('login'))

"""
Register new user
"""
@app.route('/register' , methods=['GET','POST'])
@login_required
def register():
    if request.method == 'GET':
        return render_template('register.html')
    user = User(username=request.form['username'], password=request.form['password'], email=request.form['email'])
    session.add(user)
    session.commit()
    return redirect(url_for('login'))

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
    return redirect(url_for('login', next=request.endpoint))

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
    return session.query(User).get(user_id)


#Run the app :)
if __name__ == "__main__":
    app.run(debug = True, host='0.0.0.0',port=5000)
