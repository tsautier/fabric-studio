#!/bin/bash
#===============================================================================
# SCRIPT NAME:    debcli_MBP16_deCH/addons.sh
# DESCRIPTION:    Additions
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-14
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
#===============================================================================

# Copy Certificate fikes
[ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet

# Generate Documentation link for Chrome Browser
#echo "https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/${demo}/README.md" > $BUILDDIR/url
echo "file:///home/fortinet/html/index.html" > $BUILDDIR/url

# Copy devcli postinstall template
cat $FABRIC_HOME/modules/debcli_postinst | sed \
  -e 's/INSTALL_CHROME=0/INSTALL_CHROME=1/g' \
  -e 's/INSTALL_MARKTEXT=0/INSTALL_MARKTEXT=1/g' \
  -e 's/INSTALL_ANSIBLE=0/INSTALL_ANSIBLE=0/g' \
  -e 's/KUBECTL_CLIENT=0/KUBECTL_CLIENT=1/g'                                                      >  $BUILDDIR/fortipoc/postinst

echo -e "\necho \"=> Deploy Applications to k3s\""                                                >> $BUILDDIR/fortipoc/postinst
echo -e "\necho \"10.1.1.200 debk3s\" >> /etc/hosts"                                              >> $BUILDDIR/fortipoc/postinst

#echo "=> Set Local hostnames"
#echo "10.1.1.100  *.k3s.fortidemo.ch"           >> /etc/hosts
#echo "10.1.1.100  echoserver.k3s.fortidemo.ch"  >> /etc/hosts

# Copy Demo Guide and HTML
cp -r $DEMOPATH/files/doc                   $BUILDDIR/home/fortinet
cp -r $DEMOPATH/files/html                  $BUILDDIR/home/fortinet

