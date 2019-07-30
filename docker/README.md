# Airflow Docker Image for IBM Cloud
This repository is built off airflow docker container at [puckel/docker-airflow](https://github.com/puckel/docker-airflow)

I added support for curl, vim in this image. See Dockerfile for details.

## Informations

* Based on [puckel/docker-airflow](https://github.com/puckel/docker-airflow)
* Based on Python 3.6, but I try to make it compatible to both Python2.7 and 3.x
* Install [Docker](https://www.docker.com/)
* Install [Docker Compose](https://docs.docker.com/compose/install/)

**Please consider using Python 3 for developing any Airflow related scripts since Python 2 is going to retire!**

## Run in Your Local Machine with "docker-compose"
### Build

For example, if you need to install [Extra Packages](https://pythonhosted.org/airflow/installation.html#extra-package), edit the Dockerfile and then build it using:

        docker build --rm -t local-test/docker-airflow .

### Usage (via docker-compose)
Airflow runs on SequentialExecutor by default, but enclosed are two yml files that can spin up Airflow in LocalExecutor mode or CeleryExecutor mode:

For **LocalExecutor** (ONLY RECOMMENDED FOR RUNNING LOCALLY):

        docker-compose -f docker-compose-LocalExecutor.yml up -d

For **CeleryExecutor** :

        docker-compose -f docker-compose-CeleryExecutor.yml up -d

I would suggest LocalExecutor if you just want to run it locally in your machine.

Once the containers spins up, access the webui from localhost:8080.

### To test your DAG 
* Before spinning up the container: copy your dag into **docker/dags/** folder
* After spinning up the container: ```docker cp dag.py yourcontainer:/usr/local/airflow/dag.py```

### Authentication
By default, this image disables RBAC. This can be enabled by setting environment variable `WEB_RBAC`.
If RBAC is enabled, the default username is "admin", and password is "changeme".