#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-edb-docker.sh
# DESCRIPTION:    Deploy Fortinet EmployeeDB Application
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-30
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-30 sdubois Initial version
#===============================================================================

# Environment Variables
APPNAME=edb
APPDESC="EmployeeDB Demo"
DOCKER_IMAGE=sadubois/employeedb:1.4.1
CONTAINER_PORT=8080
EXPOSE_PORT=8080

# DB-Access credentials
DB_SERVER=10.1.1.201
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=fortinet

# Optional: Mount the SSL-Certificate
TLS_CERT_PATH=$HOME/cert/fortidemo
TLS_CERT_NAME=fabric

# Stop the Docker container if its is already running
# Stop and remove the container only if it's running or exists
if [ "$(docker ps -aq -f name=^/${APPNAME}$)" ]; then
  echo "Stopping and removing existing container: $APPNAME"
  docker rm -f $APPNAME
fi

[ "$1" == "stop" ] && exit 0

echo "Checking MySQL availability at $HOST:$PORT..." > /var/log/fortinet/deploy-${APPNAME}-docker.log
while ! nc -z $DB_SERVER $DB_PORT; do
  echo "$(date) MySQL not available yet... retrying in 2 seconds" >> /var/log/fortinet/deploy-${APPNAME}-docker.log
  sleep 2
done

# Start the Container 
docker run -d \
  --name $APPNAME \
  -p $EXPOSE_PORT:$CONTAINER_PORT \
  --ulimit nproc=65535 \
  --ulimit nofile=65535:65535 \
  --memory=1g \
  --security-opt seccomp=unconfined \
  -e SPRING_PROFILES_ACTIVE=fabric-studio \
  -e SPRING_DATASOURCE_USERNAME=$DB_USER \
  -e SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD \
  $DOCKER_IMAGE >> /var/log/fortinet/deploy-${APPNAME}-docker.log 2>&1
