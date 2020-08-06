# docker_airflow
airflow with docker compose

## mysql configuration
```
-- add user and database
create user 'airflow'@'192.168.%.%' identified by 'Abcd_1234';
grant all privileges on docker_airflow.* to 'airflow'@'192.168.%.%' with grant option;
create database docker_airflow default character set utf8 default collate utf8_general_ci;
alter database hive2 character set docker_airflow;
flush privileges;
```

## airflow configuration
```
docker build -t airflow -f Dockerfile .
docker-compose -f docker-compose-LocalExecutor.yml up -d
docker exec -ti CONTAINER_ID /bin/bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
export AIRFLOW__CORE__FERNET_KEY="keys"
airflow resetdb
airflow create_user --lastname user --firstname admin --username admin --email test@abc.com --role Admin --password admin
```
