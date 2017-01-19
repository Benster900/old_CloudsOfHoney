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
from rethinkdb.errors import *
import rethinkdb as r
from config import SECRET_KEY
from datetime import datetime


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

bootstrap.init_app(app)
mail.init_app(app)
db.init_app(app)
security.init_app(app, user_datastore)
login_manager.init_app(app)

from app import main 

