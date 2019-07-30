# Charts for Airflow

## Summary
This project is meant to run on IBMCloud. Sign up a free version of IKS [here]().

## Components
* Postgres DB
* Redis
* Airflow nodes: 
    * Flower
    * Scheduler
    * Webserver
    * Worker

## Install the Chart
```
helm upgrade airflow airflow -i --debug --namespace test --set-string <any value we would like to set>
```

## User Authentication
User authentication can be enabled through rbac, which comes with Airflow since version 1.10.2. It can be enabled through `airflow/rbca` section in [values.yaml](./values.yaml)
