import os

# Get the path that the server is running from
_basedir = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '../..'))
MHN_SERVER_HOME = _basedir

# Get the path that the app is running in
_basedir = os.path.abspath(os.path.dirname(__file__))
MHN_WEB_SERVER_HOME = _basedir

# Domain or IP address of server
MHN_DOMAIN_NAME = 'cloud.localdomain'

# Open application variables
f = open('app.vars','r')

# Setup database
dbUser=f.readline().strip()
dbPass=f.readline().strip()
dbHost=f.readline().strip()
dbDatabase=f.readline().strip()
SQLALCHEMY_DATABASE_URI = "mysql+pymysql://{0}:{1}@{2}/{3}".format(dbUser, dbPass, dbHost, dbDatabase)

# Security setting
SECRET_KEY = f.readline().strip()
SECURITY_PASSWORD_HASH = f.readline().strip()
SECURITY_PASSWORD_SALT = f.readline().strip()
SECURITY_TRACKABLE = False
