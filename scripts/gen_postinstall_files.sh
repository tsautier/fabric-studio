#!/bin/bash
#===============================================================================
# SCRIPT NAME:    gen_acme_ca.sh
# DESCRIPTION:    Generate private key and certificate for ACME Private CA
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

# --- SET FABRIC_HOME DIRECTORY ---
[ "$(pwd | awk -F'/' '{ print $NF }')" == "scripts" ] && FABRIC_HOME=$(pwd | sed 's+scripts++g' | sed 's+/$++g') || FABRIC_HOME=$(pwd)

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
