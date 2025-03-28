#!/bin/bash
#===============================================================================
# SCRIPT NAME:    scripts/gen_docker_images.sh
# DESCRIPTION:    Generate Docker Images and upload to DockerHub
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-14
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
#===============================================================================
# SET STRICT MODE: Makes script safer by handling errors and undefined variables
set -euo pipefail
IFS=$'\n\t'

# Resolve the script's directory, handling symlinks if possible
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)
[ $(basename $SCRIPT_DIR) == "fabric-studio" ] && FABRIC_HOME=$SCRIPT_DIR || FABRIC_HOME=$(dirname $SCRIPT_DIR)

# verify machine architecure
ARCH=$(uname -m)
[ "$ARCH" != "x86_64" ] && echo "ERROR: $0 Wrong machine architecure, x86_64 needed" && exit 0

# Load secrets and passwords from local drive
[ -f $HOME/.tanzu-demo-hub.cfg ] && source $HOME/.tanzu-demo-hub.cfg

# verify login to dockerhub
docker pull sadubois/employeedb:1.4.1 > /dev/null 2>&1; ret=$?
if [ $ret -ne 0 ]; then 
  #docker login -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS > /dev/null 2>&1; ret=$?
  docker login -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS 
  if [ $ret -ne 0 ]; then 
    echo "ERROR: $0 failed to login to docker hub"
    echo "       => docker login $REGISTRY_NAME -u $REGISTRY_USER -p $REGISTRY_PASS"; exit 1
  fi
fi

echo "$FABRIC_HOME/docker/"
for app in $(ls -1 $FABRIC_HOME/docker/); do
  [ ! -f $FABRIC_HOME/docker/${app}/Dockerfile ] && continue

  docker build -f $FABRIC_HOME/docker/${app}/Dockerfile -t ${app}$:latest $FABRIC_HOME/docker/${app}

done

exit



# Certificate name and path
CERTDIR=$FABRIC_HOME/cert

export COPYFILE_DISABLE=1

export BUILDDIR=/tmp/build_$$

rm -f ../postinstall-files/kbg_screen1.tgz ../postinstall-files/kbg_screen.tgz

echo "Generate K3s postinstall files ($FABRIC_HOME/files/kbg_screen.tgz)"
rm -rf $BUILDDIR && mkdir -p $BUILDDIR
cp -r $FABRIC_HOME/files/postinstall-debian-k3s/* $BUILDDIR
cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet
cd $BUILDDIR && tar cfz $FABRIC_HOME/postinstall/k3s.tgz * && cd $FABRIC_HOME

exit

echo "Generate Client files ($FABRIC_HOME/postinstall-files/kbg_screen.tgz)"
rm -rf $BUILDDIR && mkdir -p $BUILDDIR
cp -r postinstall-debian-client/* $BUILDDIR
cp -r Certificates $BUILDDIR/home/fortinet
cd $BUILDDIR && tar cfz $FABRIC_HOME/postinstall-files/kbg_screen.tgz * && cd $FABRIC_HOME

echo "Generate MySQL files ($FABRIC_HOME/postinstall-files/mysql.tgz)"
rm -rf $BUILDDIR && mkdir -p $BUILDDIR
cp -r postinstall-debian-mysql/* $BUILDDIR
cd $BUILDDIR && tar cfz $FABRIC_HOME/postinstall-files/mysql.tgz * && cd $FABRIC_HOME

exit
# Copy postinstall scripts to the Project
cp postinstall-files/k3s.tgz Kubernetes/config/1/LXC/k3s.tgz
cp postinstall-files/kbg_screen.tgz Kubernetes/config/1/DEBIAN/kbg_screen.tgz
cp postinstall-files/mysql.tgz Kubernetes/config/1/DEBIAN/mysql.tgz

rm -rf $BUILDDIR
