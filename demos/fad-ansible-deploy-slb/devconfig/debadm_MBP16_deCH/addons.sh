#!/bin/bash
#===============================================================================
# SCRIPT NAME:    debadm_MBP16_deCH/addons.sh
# DESCRIPTION:    Additions
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-14
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
#===============================================================================

# Copy message of the Day
cp -r $DEMOPATH/files/etc                   $BUILDDIR

# Copy Certificate files  
[ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet

# Generate Documentation link for Chrome Browser
echo "file:///home/fortinet/html/index.html" > $BUILDDIR/url
 
# Copy Demo Guide and HTML
cp -r $DEMOPATH/files/ansible               $BUILDDIR/home/fortinet
cp -r $DEMOPATH/files/html                  $BUILDDIR/home/fortinet

echo -e "# install FortiADC Ansible Modules"                                              >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"ansible-galaxy collection install fortinet.fortiadc\""        >> $BUILDDIR/fortipoc/postinst

