# VERSION 1.10.11
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7.8-slim-buster
LABEL maintainer="laomie_"

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow and PYTHONPATH
ARG AIRFLOW_VERSION=1.10.11
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ENV PYTHONPATH=${AIRFLOW_USER_HOME}/dags

COPY ./docker/deb/sources.list /etc/apt/sources.list

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# Disable noisy "Handling signal" log messages:
# ENV GUNICORN_CMD_ARGS --log-level WARNING

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        vim \
        openssh-server \

    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ -U pip setuptools wheel \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ pytz \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ pyOpenSSL \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ ndg-httpsclient \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ pyasn1 \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ apache-airflow[crypto,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

# airflow timezone patch
COPY ./docker/airflow/timezone.py /usr/local/lib/python3.7/site-packages/airflow/utils/timezone.py
COPY ./docker/airflow/sqlalchemy.py /usr/local/lib/python3.7/site-packages/airflow/utils/sqlalchemy.py
COPY ./docker/airflow/master.html /usr/local/lib/python3.7/site-packages/airflow/www/templates/admin/master.html

# app requirements
# COPY ./docker/python/requirements.txt /requirements.txt
# RUN pip install -i https://mirrors.aliyun.com/pypi/simple/ -r /requirements.txt 

COPY ./docker/script/entrypoint.sh /entrypoint.sh
COPY ./docker/config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg

RUN /etc/init.d/ssh start
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
