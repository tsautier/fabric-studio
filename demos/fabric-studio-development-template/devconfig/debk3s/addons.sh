#!/bin/bash
#===============================================================================
# SCRIPT NAME:    addons.sh
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

# Copy Scripts
cp $DEMOPATH/devconfig/${device}/bin/deploy-echoserver-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-edb-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-globex-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-apex-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-acme-ingress.sh $BUILDDIR/home/fortinet/bin

echo -e "\n# Deploy Applications to k3s\""                                                        >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-echoserver-ingress.sh > /dev/null 2>&1\""   >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-edb-ingress.sh > /dev/null 2>&1\""          >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-globex-ingress.sh > /dev/null 2>&1\""       >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-apex-ingress.sh > /dev/null 2>&1\""         >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-acme-ingress.sh > /dev/null 2>&1\""         >> $BUILDDIR/fortipoc/postinst

echo -e "\n# Deploy Applications to k3s\""                                                        >> $BUILDDIR/fabric/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-echoserver-ingress.sh > /dev/null 2>&1\""   >> $BUILDDIR/fabric/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-edb-ingress.sh > /dev/null 2>&1\""          >> $BUILDDIR/fabric/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-globex-ingress.sh > /dev/null 2>&1\""       >> $BUILDDIR/fabric/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-apex-ingress.sh > /dev/null 2>&1\""         >> $BUILDDIR/fabric/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-acme-ingress.sh > /dev/null 2>&1\""         >> $BUILDDIR/fabric/postinst

