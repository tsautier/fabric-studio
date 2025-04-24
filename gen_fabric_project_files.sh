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
  printf " ▪ %-60s\n" "$1" 
}

# Define local variables

# Generate devconfig files
for demo in $(ls -1 $FABRIC_HOME/demos | grep -v zip); do
[ "fad-ansible-deploy-slb" != "$demo" ] && continue
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
      DEMO_DEVICE_CONFIG=$DEMOPATH/devconfig/${device}
      DEVICE_CONFIG_FILE=$STOREDIR/${demo}/${device}.tgz

      if [ -f $DEVICE_CONFIG_FILE ]; then
        stt1=$(find "$DEVICE_CONFIG" -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
        stt2=$(find "$DEMO_DEVICE_CONFIG" -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
        if [ $stt1 -eq 0 -a $stt2 -eq 0 ]; then
          [ -d $STAGEDIR/config/1/DEBIAN ] && cp $DEVICE_CONFIG_FILE $STAGEDIR/config/1/DEBIAN
          printf " ▪ %-40s %-55s %-15s\n" "Generating Device config for $device" "files/$demo/${device}.tgz"    "no-change"
          continue
        fi
      fi

      rm -rf $BUILDDIR && mkdir -p $BUILDDIR
      cp -r $DEVICE_CONFIG/* $BUILDDIR

      # Execute fabric demo dedicated configuration script for that device
      [ -x $DEMO_DEVICE_CONFIG/addons.sh ] && source $DEMO_DEVICE_CONFIG/addons.sh

      OLDDIR=$PWD && cd $BUILDDIR && tar cfz $DEVICE_CONFIG_FILE * && cd $OLDDIR
      [ -d $STAGEDIR/config/1/DEBIAN ] && cp $DEVICE_CONFIG_FILE $STAGEDIR/config/1/DEBIAN

      printf " ▪ %-40s %-55s %-15s\n" "Generating Device config for $device" "files/$demo/${device}.tgz"    "generated"
    done
  fi

  # Pack fabric-studio demo package
  [ -f $STOREDIR/${demo}.zip ] && rm $STOREDIR/${demo}.zip
  OLDDIR=$PWD && cd $STAGEDIR && zip -rq $STOREDIR/${demo}.zip * && cd $OLDDIR
echo "$STOREDIR/${demo}.zip"
done

exit

echo "Generating fabric studio project files"

# Generate devconfig files
for device in $(ls -1 $FABRIC_HOME/devconfig); do
  BUILDDIR=/tmp/build_${device}_$$
  DEVICE_CONFIG=$FABRIC_HOME/devconfig/${device}
  DEVICE_CONFIG_FILE=$FABRIC_HOME/files/devconfig-${device}.tgz

  if [ -f $DEVICE_CONFIG_FILE ]; then 
    stt=$(find "$DEVICE_CONFIG" -type f -newer "$DEVICE_CONFIG_FILE" | wc -l | awk '{ print $1 }')
    if [ $stt -eq 0 ]; then
      printf " ▪ %-60s %s\n" "Generating Device config for $device"    "no-changes"
      continue
    fi
  fi

  rm -rf $BUILDDIR && mkdir -p $BUILDDIR
  cp -r $FABRIC_HOME/devconfig/${device}/* $BUILDDIR
  [ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet 
  [ "$device" == "debian-client" ] && echo "https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/fortinet-sni-based-cert-selection/README.md" > $BUILDDIR/url
  cd $BUILDDIR && tar cfz $FABRIC_HOME/files/devconfig-${device}.tgz * && cd $FABRIC_HOME

echo "$FABRIC_HOME/files/devconfig-${device}.tgz"
  printf " ▪ %-60s %-30s %s\n" "Generating Device config for $device"    "generated"

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





