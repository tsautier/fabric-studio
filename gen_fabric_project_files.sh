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

# Define local variables

echo "Generating fabric studio project files"

# Generate device-config files
for device in $(ls -1 $FABRIC_HOME/device-config); do
  BUILDDIR=/tmp/build_${device}_$$
  DEVICE_CONFIG=$FABRIC_HOME/device-config/${device}
  DEVICE_CONFIG_FILE=$FABRIC_HOME/files/device-config-${device}.tgz

  if [ -f $DEVICE_CONFIG_FILE ]; then 
    stt=$(find "$DEVICE_CONFIG" -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
    if [ $stt -eq 0 ]; then
      printf " ▪ %-60s %s\n" "Generating Device config for $device"    "no-changes"
      continue
    fi
  fi

  rm -rf $BUILDDIR && mkdir -p $BUILDDIR
  cp -r $FABRIC_HOME/device-config/${device}/* $BUILDDIR
  [ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $FABRIC_HOME/corp $BUILDDIR/home/fortinet 
  [ "$device" == "debian-client" ] && echo "https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/fortinet-sni-based-cert-selection/README.md" > $BUILDDIR/url
  cd $BUILDDIR && tar cfz $FABRIC_HOME/files/device-config-${device}.tgz * && cd $FABRIC_HOME

echo "$FABRIC_HOME/files/device-config-${device}.tgz"
  printf " ▪ %-60s %s\n" "Generating Device config for $device"    "generated"

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





