FROM ubuntu:14.04

MAINTAINER john.desilvio@yahoo.com

RUN sudo apt-get update

# Git
RUN sudo apt-get install -y git-core

# PostgreSQL
RUN sudo apt-get install -y postgresql postgresql-server-dev-all libpq-dev python-psycopg2

# Redis
RUN sudo apt-get install -y redis-server

# Python virtualenv (optional)
RUN sudo apt-get install -y python-virtualenv

# Python requirements
RUN sudo apt-get install -y python-dev build-essential libjpeg-dev libssl-dev swig libffi-dev dbus libdbus-1-dev libdbus-glib-1-dev

# Upgrade pip to latest version
RUN pip install -U pip

# Workaround for bug in PyCParser
RUN pip install git+https://github.com/eliben/pycparser@release_v2.14

# Add code
ADD ./pybossa /pybossa
WORKDIR /pybossa

# Install the required libraries
RUN pip install -r requirements.txt

# Run Redis sentinel node
RUN ls contrib/
RUN redis-server contrib/sentinel.conf --sentinel

# Set up PostgreSQL database
#ENV POSTGRES_USER postgres
#ENV POSTGRES_PASSWORD
#ENV POSTGRES_DB pybossa
#ENV PGHOST localhost

# Set up PostgreSQL database
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

USER postgres

RUN /etc/init.d/postgresql start &&\
    #sudo su - postgres &&\
    psql --command "CREATE USER pybossa WITH SUPERUSER PASSWORD 'tester';" &&\
    createdb pybossa -O pybossa

# Populate the database
RUN python cli.py db_create

# Copy config files from templates
#cp settings_local.py.tmpl settings_local.py
#cp alembic.ini.template alembic.ini

# Scheduler and worker task setup (optional?)
#rqscheduler --host IP-of-your-redis-master-node
#python app_context_rqworker.py scheduled_jobs super high medium low

# Start the Redis Sentinel
RUN redis-server contrib/redis.conf
RUN redis-server contrib/sentinel.conf --sentinel

EXPOSE 80

#CMD ["python", "app.py"]
