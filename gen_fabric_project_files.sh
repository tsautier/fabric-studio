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

REMOTE_REPO=1
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
SERVER="10.7.80.20"
BASE_DIR="/srv/fsrepo/html/prod"
# Prompt for remote user
[ -z "$REMOTE_USER" ] && read -rp "Remote SSH/SCP username: " REMOTE_USER

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
  generated=0
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
          printf " ▪ %-55s %-75s %-15s\n" "Generating Device config for $device" "files/$demo/${device}.tgz"    "no-change"
          continue
        fi
      fi

      rm -rf $BUILDDIR && mkdir -p $BUILDDIR
      cp -r $DEVICE_CONFIG/* $BUILDDIR

      # Execute fabric demo dedicated configuration script for that device
      [ -x $DEMO_DEVICE_CONFIG/addons.sh ] && source $DEMO_DEVICE_CONFIG/addons.sh

      # pack the file
      tar czf $DEVICE_CONFIG_FILE --exclude='._*' --exclude='._.*' -C $BUILDDIR .
      [ -d $STAGEDIR/config/1/DEBIAN ] && cp $DEVICE_CONFIG_FILE $STAGEDIR/config/1/DEBIAN

      printf " ▪ %-55s %-75s %-15s\n" "Generating Device config for $device" "files/$demo/${device}.tgz"    "generated"
      generated=1
    done
  fi

  # Pack the archive only if there was changes in the devices or archive does not exist
  if [ $generated -ne 0 -o ! -f $STOREDIR/${demo}.zip ]; then
    [ -f $STOREDIR/${demo}.zip ] && rm $STOREDIR/${demo}.zip
    (cd "$STAGEDIR" && zip -rq "$STOREDIR/${demo}.zip" .)

    printf " ▪ %-55s %-75s %-15s\n" "Fabric Archive ($demo)" "files/${demo}.zip"    "created"
  else
    printf " ▪ %-55s %-75s %-15s\n" "Fabric Archive ($demo)" "files/${demo}.zip"    "no-change"
  fi

  if [ $REMOTE_REPO -eq 1 ]; then 
    #cp files/fgt-proxy-kubernetes-sdn-connector-export-1.1.0.zip files/fgt-proxy-kubernetes-sdn-connector.zip
    #cksum files/fgt-proxy-kubernetes-sdn-connector.zip

    # Upload file to repository server 
    cksum_loc=$(cksum $STOREDIR/${demo}.zip | awk '{ print $1 }') 
    cksum_rmt=$(ssh $SSH_OPTIONS ${REMOTE_USER}@${SERVER} "[ -f ${BASE_DIR}/templates/${REMOTE_USER}_${demo}.zip ] && cksum ${BASE_DIR}/templates/${REMOTE_USER}_${demo}.zip | awk '{ print \$1 }'" 2>/dev/null)

    [ "$cksum_rmt" == "" ] && cksum_rmt=0
    if [ $cksum_loc -ne $cksum_rmt ]; then 
      scp $FABRIC_HOME/files/${demo}.zip ${REMOTE_USER}@${SERVER}:${BASE_DIR}/templates/${REMOTE_USER}_${demo}.zip > /tmp/fprepo.log 2>&1; ret=$?
      if [ $ret -eq 0 ]; then 
        printf " ▪ %-55s %-75s %-15s\n" "Uploading Fabric Archive to Repo Server ($SERVER)" "files/${demo}.zip"    "completed"
        ssh $SSH_OPTIONS {REMOTE_USER}@${SERVER} "/opt/ftnt/bin/fprepo refresh ${BASE_DIR}" > /tmp/fprepo.log 2>&1; ret=$?
        if [ $ret -eq 0 ]; then 
          printf " ▪ %-55s %-75s %-15s\n" "Updating Repo Server Repository" "$BASE_DIR/Release"    "completed"
          cat /tmp/fprepo.log
        else
          printf " ▪ %-55s %-75s %-15s\n" "Updating Repo Server Repository" "$BASE_DIR/Release"    "failed"
          cat /tmp/fprepo.log
        fi
      else
        printf " ▪ %-55s %-75s %-15s\n" "Uploading Fabric Archive to Repo Server ($SERVER)" "files/${demo}.zip"    "failed"
        cat /tmp/fprepo.log
      fi
    fi
  fi
done

exit
