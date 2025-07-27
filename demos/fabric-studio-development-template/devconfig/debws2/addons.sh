#!/bin/bash
#===============================================================================
# SCRIPT NAME:    debws1/addons.sh
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
cp $DEMOPATH/devconfig/${device}/bin/deploy-edb-docker.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-apex-docker.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-globex-docker.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-acme-docker.sh $BUILDDIR/home/fortinet/bin

#echo -e "\n# Deploy Docker Applications\""                                                        >> $BUILDDIR/fabric/postinst
#echo -e "su - fortinet -c \"docker run -d -p 8081:80 --name globex sadubois/globex:latest\""      >> $BUILDDIR/fabric/postinst
#echo -e "su - fortinet -c \"docker run -d -p 8082:80 --name apex sadubois/apex:latest\""          >> $BUILDDIR/fabric/postinst
#echo -e "su - fortinet -c \"docker run -d -p 8083:80 --name acme sadubois/acme:latest\""          >> $BUILDDIR/fabric/postinst

echo -e "\n# Deploy EmployeeDB Applications\""                                                    >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-edb-docker.sh\""                             >> $BUILDDIR/fortipoc/postinst
#echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-globex-docker.sh\""                          >> $BUILDDIR/fortipoc/postinst
#echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-aspec-docker.sh\""                           >> $BUILDDIR/fortipoc/postinst
#echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-acme-docker.sh\""                            >> $BUILDDIR/fortipoc/postinst

