import os

# Get the path that the server is running from
basedir = os.path.abspath(os.path.dirname(__file__))
MHN_SERVER_HOME = basedir

# Get the path that the app is running in
_basedir = os.path.abspath(os.path.dirname(__file__))
MHN_WEB_SERVER_HOME = _basedir

# Domain or IP address of server
COH_DOMAIN_NAME = 'cloud.localdomain'

# Open application variables
f = open(os.path.join(os.path.dirname( __file__ ),'app.vars'),'r')

# Celery settings
celery_broker='redis://localhost:6379'
celery_backend='redis://localhost:6379'

# Enable user registration page
SECURITY_REGISTERABLE = True

# Setup database
dbUser=f.readline().strip()
dbPass=f.readline().strip()
dbHost=f.readline().strip()
dbDatabase=f.readline().strip()
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_DATABASE_URI = "mysql+pymysql://{0}:{1}@{2}/{3}".format(dbUser, dbPass, dbHost, dbDatabase)

# Security setting
SECRET_KEY = f.readline().strip()
SECURITY_PASSWORD_HASH = f.readline().strip()
SECURITY_PASSWORD_SALT = f.readline().strip()
SECURITY_TRACKABLE = False
