# VERSION 1.10.3
# Based on airflow docker image from: https://hub.docker.com/r/puckel/docker-airflow/

FROM puckel/docker-airflow:1.10.3
MAINTAINER Shengyi

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.3
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ARG SPARK_VERSION=2.4.3
ARG HADOOP_VERSION=hadoop2.7

# Airflow rest plugin
ARG AIRFLOW_REST_VERSION=1.0.5
ARG AIRFLOW_IMPATIENT_VERSION=0.0.1

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

USER root

COPY patches/ $AIRFLOW_HOME/patches/
COPY python/ /python

RUN set -ex \
    && mkdir -p /usr/share/man/man1 \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        openjdk-8-jre-headless \
        ca-certificates-java \
        openssh-client \
        net-tools \
        dnsutils \
	    vim \
	    curl \
	    zip \
	    unzip \
	    wget \
	    procps \
    && pip install jinja2 \
                   apache-airflow[crypto,postgres,s3,password,slack,github_enterprise]==$AIRFLOW_VERSION \
                   kubernetes==9.0.0 \
    # Replace kube_config.py module in kubernetes python package to cope with issue at https://github.com/kubernetes-client/python/issues/525
    && cp $AIRFLOW_HOME/patches/kubernetes/config/kube_config.py $(python -c "import site; print(site.getsitepackages()[0])")/kubernetes/config/ \
    # Install customized package
    && cd /python && python /python/setup.py install && cd - \
    # Install rest api
    && wget https://github.com/teamclairvoyant/airflow-rest-api-plugin/archive/v$AIRFLOW_REST_VERSION.zip \
    && unzip v$AIRFLOW_REST_VERSION.zip \
    && mkdir -p $AIRFLOW_HOME/plugins/ \
    && cp -r airflow-rest-api-plugin-$AIRFLOW_REST_VERSION/plugins/* $AIRFLOW_HOME/plugins/ \
    && wget http://apache.mirrors.hoobly.com/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-$HADOOP_VERSION.tgz -O $AIRFLOW_HOME/spark-$SPARK_VERSION-bin-$HADOOP_VERSION.tgz \
    && tar zxvf $AIRFLOW_HOME/spark-$SPARK_VERSION-bin-$HADOOP_VERSION.tgz --directory $AIRFLOW_HOME \
    # Install ibmcloud cli
    && curl -sL https://ibm.biz/idt-installer | bash

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $AIRFLOW_HOME/spark-$SPARK_VERSION-bin-$HADOOP_VERSION/bin:$PATH

COPY script/entrypoint.sh /entrypoint.sh
COPY dags/ $AIRFLOW_HOME/dags/
COPY config/airflow.cfg $AIRFLOW_HOME/airflow.cfg
COPY config/webserver_config.py $AIRFLOW_HOME/webserver_config.py
# COPY script/init_user.py $AIRFLOW_HOME/init_user.py

RUN chmod +x /entrypoint.sh
RUN chown -R airflow: $AIRFLOW_HOME

EXPOSE 8080 5555 8793

USER airflow
WORKDIR $AIRFLOW_HOME
ENTRYPOINT ["/entrypoint.sh"]
