# Airflow on Kubernetes for Impatient

## Contributing
If you find this repo useful here's how you can help:

* Send a pull request with your new features and bug fixes
* Help with existing issues
* Help new users with issues they may encounter
* Support the development of this image and star this repo !

## Description
This project is to create an Airflow server on top of Kuberntes for Data Engineering and Science job scheduling. Airflow is an open-source Apache licensed tool for work scheduling.

This project consists of following components:
* Airflow: 1.10.3.

## Quick Start for Impatient

### Quick Start Guild
#### 1. Prerequisites
* Build Airflow Docker image from [docker folder](./docker). I have built one for public at here: [psyking841/apache-airflow:1.10.3](https://cloud.docker.com/repository/docker/psyking841/apache-airflow).
* Have access to a Kubernetes cluster in IBM Cloud Kubernetes Service ([sign up](https://www.ibm.com/cloud/container-service))
    * You need to populate IBMCloud related fields in [values.yaml](./charts/airflow/values.yaml)
* Have IBM Cloud CLI installed (Run ```curl -sL https://ibm.biz/idt-installer | bash```). This should install both kubectl and helm command line for you. 

#### 2. Install Airflow to your cluster
```bash
helm install charts/airflow --name airflow-for-impatient
```
By default webrbac is turned on. Default username/password is admin/admin.

Expose the webserver to your localhost
```bash
kubectl port-forward service/webserver 8080:8080
```

#### 3. Push Your Dag
Copy your dag to master node (you need to run `kubectl get all` to get XXXXX):
```bash
kubectl cp <dag>.py webserver-XXXXX:/opt/local/airflow/dags
```
This will take couple of minutes for your dag to show up in the WebUI.

Enjoy!
