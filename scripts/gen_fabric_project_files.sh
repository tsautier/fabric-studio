#!/bin/bash
#===============================================================================
# SCRIPT NAME:    gen_fabric_project_files.sh
# DESCRIPTION:    
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-23
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



echo "SCRIPT_DIR:$SCRIPT_DIR"
echo "FABRIC_HOME:$FABRIC_HOME"

exit

for n in $(ls -1 $FABRIC_HOME/device_config); do

echo "N:$n"

done

echo " ▪ OKTA Username Claim          $TDH_OKTA_USERNAME_CLAIM"



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





