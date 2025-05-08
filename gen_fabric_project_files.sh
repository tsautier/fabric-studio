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

# Resolve the script's directory, handling symlinks if possible
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)
[ $(basename $SCRIPT_DIR) == "fabric-studio" ] && FABRIC_HOME=$SCRIPT_DIR || FABRIC_HOME=$(dirname $SCRIPT_DIR)

# Local functions
subhead () { 
  #printf " ▪ %-60s %s\n" "$1" "$stt" 
  printf " ▪ %-75s\n" "$1" 
}

# Define local variables

# Generate devconfig files
for demo in $(ls -1 $FABRIC_HOME/demos | grep -v zip); do
#[ "fad-ansible-deploy-slb" != "$demo" ] && continue
[ "fgt-kubernetes-sdn-connector" != "$demo" ] && continue
  DEMOPATH="${FABRIC_HOME}/demos/${demo}"
  STOREDIR="${FABRIC_HOME}/files"
  STAGEDIR=/tmp/fabric_studio_stage
  [ ! -d $STOREDIR/${demo} ] && mkdir -p $STOREDIR/${demo}

  # Prepare Stage Directory
  rm -rf $STAGEDIR && mkdir -p $STAGEDIR
  [ -d $DEMOPATH/fabric ] && cp -r $DEMOPATH/fabric/* $STAGEDIR

  echo ""
  echo "Building project files for ($demo)"

  # Generate devconfig files
  if [ -d $DEMOPATH/devconfig ]; then 
    for device in $(ls -1 $DEMOPATH/devconfig 2>/dev/null); do
      #BUILDDIR=/tmp/build_${device}_$$
      BUILDDIR=/tmp/fabric_studio_build_${device}
      DEVICE_CONFIG=$FABRIC_HOME/devconfig/${device}
      DEVICE_INFO=$FABRIC_HOME/devconfig/.${device}.inf
      DEMO_DEVICE_CONFIG=$DEMOPATH/devconfig/${device}
      DEVICE_CONFIG_FILE=$STOREDIR/${demo}/${device}.tgz

      [ -f $DEVICE_INFO ] && read MODULE_NAME < $DEVICE_INFO || MODULE_NAME=debbla_postinst

      if [ -f $DEVICE_CONFIG_FILE ]; then
        stt1=$(find "$DEVICE_CONFIG" -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
        stt2=$(find "$DEMO_DEVICE_CONFIG" -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
        stt3=$(find ./modules -name $MODULE_NAME -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
        if [ $stt1 -eq 0 -a $stt2 -eq 0 -a $stt3 -eq 0 ]; then
          [ -d $STAGEDIR/config/1/DEBIAN ] && cp $DEVICE_CONFIG_FILE $STAGEDIR/config/1/DEBIAN
          printf " ▪ %-55s %-65s %-15s\n" "Generating Device config for $device" "files/$demo/${device}.tgz"    "no-change"
          continue
        fi
      fi

      rm -rf $BUILDDIR && mkdir -p $BUILDDIR
      cp -r $DEVICE_CONFIG/* $BUILDDIR

      # Execute fabric demo dedicated configuration script for that device
      [ -x $DEMO_DEVICE_CONFIG/addons.sh ] && source $DEMO_DEVICE_CONFIG/addons.sh

#[ "$device" == "debk3s_flannel_SNAT" ] && echo "BUILDDIR:$BUILDDIR" && exit
      # pack the file
      tar czf $DEVICE_CONFIG_FILE --exclude='._*' --exclude='._.*' -C $BUILDDIR .
      [ -d $STAGEDIR/config/1/DEBIAN ] && cp $DEVICE_CONFIG_FILE $STAGEDIR/config/1/DEBIAN

      printf " ▪ %-55s %-65s %-15s\n" "Generating Device config for $device" "files/$demo/${device}.tgz"    "generated"
    done
  fi

  # Pack fabric-studio demo package
  [ -f $STOREDIR/${demo}.zip ] && rm $STOREDIR/${demo}.zip
  (cd "$STAGEDIR" && zip -rq "$STOREDIR/${demo}.zip" .)

  #OLDDIR=$PWD && cd $STAGEDIR && zip -rq $STOREDIR/${demo}.zip * && cd $OLDDIR
done

exit
