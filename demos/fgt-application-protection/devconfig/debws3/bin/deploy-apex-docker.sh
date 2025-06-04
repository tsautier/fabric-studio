#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-apex-docker.sh
# DESCRIPTION:    Deploy Fortinet EmployeeDB Application
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-30
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-30 sdubois Initial version
#===============================================================================

# Environment Variables
APPNAME=apex
APPDESC="APEX Application"
DOCKER_IMAGE=sadubois/globex:latest
CONTAINER_PORT=8080
EXPOSE_PORT=80

# Stop the Docker container if its is already running
# Stop and remove the container only if it's running or exists
if [ "$(docker ps -aq -f name=^/${APPNAME}$)" ]; then
  echo "Stopping and removing existing container: $APPNAME"
  docker rm -f $APPNAME
fi

[ "$1" == "stop" ] && exit 0

# Start the Container 
docker run -d \
  --name $APPNAME \
  -p $EXPOSE_PORT:$CONTAINER_PORT \
  $DOCKER_IMAGE > /var/log/deploy-${APPNAME}-docker.log 2>&1
