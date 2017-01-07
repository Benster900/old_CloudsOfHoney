import os

_basedir = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '../..'))
MHN_SERVER_HOME = _basedir

_basedir = os.path.abspath(os.path.dirname(__file__))
MHN_WEB_SERVER_HOME = _basedir

_basedir = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '../..', 'scripts'))
MHN_SCRIPTS_SERVER_HOME = _basedir

# Domain or IP address of server
MHN_DOMAIN_NAME = 'cloud.localdomain'

SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://<user>:<password>@127.0.0.1/fist-test'
