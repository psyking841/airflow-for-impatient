#!/usr/bin/env bash

TRY_LOOP="30"

: "${REDIS_HOST:="airflow-redis"}"
: "${REDIS_PORT:="6379"}"
: "${REDIS_PASSWORD:=""}"

: "${POSTGRES_HOST:="airflow-postgres"}"
: "${POSTGRES_PORT:="5432"}"
: "${POSTGRES_USER:="airflow"}"
: "${POSTGRES_PASSWORD:="airflow"}"
: "${POSTGRES_DB:="airflow"}"

# Defaults and back-compat
: "${AIRFLOW__CORE__FERNET_KEY:=${FERNET_KEY:=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}}"
: "${AIRFLOW__CORE__EXECUTOR:=${EXECUTOR:-Sequential}Executor}"
: "${AIRFLOW__WEBSERVER__RBAC:=${WEB_RBAC:-False}}"

# REST api default values
: "${AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_HTTP_TOKEN_HEADER_NAME:=${REST_API_PLUGIN_HTTP_TOKEN_HEADER_NAME:-rest_api_plugin_http_token}}"
: "${AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_EXPECTED_HTTP_TOKEN:=${REST_API_TOKEN:-changeme}}"

: "${AIRFLOW_DEFAULT_USER:=${AIRFLOW_USER:-admin}}"
: "${AIRFLOW_DEFAULT_PASSWORD:=${AIRFLOW_PASSWORD:-admin}}"

# IBM Cloud
: "${IBMCLOUD_API_KEY:=${IBMCLOUD_API_KEY:-changeme}}"
: "${IBMCLOUD_IKS_REGION:=${IBMCLOUD_IKS_REGION:-us-south}}"
: "${KUBE_CLUSTER:=${KUBE_CLUSTER:-mycluster}}"

export \
  AIRFLOW__CELERY__BROKER_URL \
  AIRFLOW__CELERY__RESULT_BACKEND \
  AIRFLOW__CORE__EXECUTOR \
  AIRFLOW__CORE__FERNET_KEY \
  AIRFLOW__CORE__LOAD_EXAMPLES \
  AIRFLOW__CORE__SQL_ALCHEMY_CONN \
  AIRFLOW__WEBSERVER__RBAC \
  AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_HTTP_TOKEN_HEADER_NAME \
  AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_EXPECTED_HTTP_TOKEN

# Load DAGs exemples (default: Yes)
if [[ "${LOAD_EX:=n}" == n ]]
then
  AIRFLOW__CORE__LOAD_EXAMPLES=False
else
  AIRFLOW__CORE__LOAD_EXAMPLES=True
fi

# Install custome python package if requirements.txt is present
if [ -e "/requirements.txt" ]; then
    $(which pip) install --user -r /requirements.txt
fi

if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_PREFIX=:${REDIS_PASSWORD}@
else
    REDIS_PREFIX=
fi

wait_for_port() {
  local name="$1" host="$2" port="$3"
  local j=0
  while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
    j=$((j+1))
    if [ $j -ge $TRY_LOOP ]; then
      echo >&2 "$(date) - $host:$port still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for $name... $j/$TRY_LOOP"
    sleep 20
  done
}

if [ "$AIRFLOW__CORE__EXECUTOR" != "SequentialExecutor" ]; then
  AIRFLOW__CORE__SQL_ALCHEMY_CONN="postgresql+psycopg2://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
  AIRFLOW__CELERY__RESULT_BACKEND="db+postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
  wait_for_port "Postgres" "$POSTGRES_HOST" "$POSTGRES_PORT"
fi

if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]; then
  AIRFLOW__CELERY__BROKER_URL="redis://$REDIS_PREFIX$REDIS_HOST:$REDIS_PORT/1"
  wait_for_port "Redis" "$REDIS_HOST" "$REDIS_PORT"
fi

case "$1" in
  webserver)
    # If running in ibmcloud kubernetes, setup kubeconfig for python kubernetes module
    ibmcloud login -a cloud.ibm.com --apikey "${IBMCLOUD_API_KEY}" -r ${IBMCLOUD_IKS_REGION} >> /dev/null 2>&1
    ibmcloud plugin install kubernetes-service
    $(ibmcloud ks cluster-config --cluster ${KUBE_CLUSTER} --export)

    # Start airflow init process
    airflow initdb

    if [ "$AIRFLOW__WEBSERVER__RBAC" = "True" ];
    then
      # This will failed if there is an existing user with same name
      airflow create_user -r Admin -u ${AIRFLOW_DEFAULT_USER} -e ${AIRFLOW_DEFAULT_USER}@ibm.com -p ${AIRFLOW_DEFAULT_PASSWORD} -f Admin -l User
    fi

#    if [ "$AIRFLOW__WEBSERVER__AUTHENTICATE" = "True" ] && [ "$AIRFLOW__WEBSERVER__AUTH_BACKEND" = "airflow.contrib.auth.backends.password_auth" ];
#    then
#      ~/init_user.py -u ${AIRFLOW_DEFAULT_USER} -p ${AIRFLOW_DEFAULT_PASSWORD}
#    fi

    if [ "$AIRFLOW__CORE__EXECUTOR" = "LocalExecutor" ];
    then
      # With the "Local" executor it should all run in one container.
      airflow scheduler &
    fi

    # Start webserver
    airflow webserver > ~/stdout.log
    ;;
  worker|scheduler)
    # To give the webserver time to run initdb.
    sleep 10
    airflow $@ > ~/stdout.log
    ;;
  flower)
    sleep 10
    airflow flower > ~/stdout.log
    ;;
  version)
    airflow version
    ;;
  *)
    # The command is something like bash, not an airflow subcommand. Just run it in the right environment.
    exec "$@"
    ;;
esac
