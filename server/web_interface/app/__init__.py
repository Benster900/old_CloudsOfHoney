from flask import Flask
from flask_bootstrap import Bootstrap
from flask_mail import Mail
from flask_sqlalchemy import SQLAlchemy
from flask_security import Security
from config import * 
from config import basedir

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
from config import SECRET_KEY
from datetime import datetime

#Mongo 
from flask_pymongo import PyMongo

# app setup
bootstrap = Bootstrap()
mail = Mail()
db = SQLAlchemy()
security = Security()
login_manager = LoginManager()


#def create_app(config_name):
from .models import user_datastore, User, Role
app = Flask(__name__)
app.config.from_object('config')

# init celery 
app.config.update(CELERY_BROKER_URL=celery_broker,CELERY_RESULT_BACKEND=celery_backend)
celery = make_celery(app)

bootstrap.init_app(app)
mail.init_app(app)
db.init_app(app)
security.init_app(app, user_datastore)
login_manager.init_app(app)

# connect to another MongoDB database on the same host
app.config['MONGO_DBNAME'] = 'cloudsofhoney'
mongo = PyMongo(app, config_prefix='MONGO')

from app import main 

