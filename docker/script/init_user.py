#!/usr/bin/env python

import argparse
from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser

parser = argparse.ArgumentParser()
parser.add_argument('-u', dest='user', help='Airflow init user')
parser.add_argument('-p', dest='password', help='Init user default password')
args = parser.parse_args()

user = PasswordUser(models.User())
user.username = args.user
user.password = args.password
session = settings.Session()
session.add(user)
session.commit()
session.close()