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

# Copy Message of the Day
cp $DEMOPATH/files/etc/motd_k3s $BUILDDIR/etc/motd

# Copy Scripts
cp $DEMOPATH/devconfig/${device}/bin/deploy-echoserver-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-edb-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-globex-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-apex-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-acme-ingress.sh $BUILDDIR/home/fortinet/bin
cp $DEMOPATH/devconfig/${device}/bin/deploy-toolbox-ingress.sh $BUILDDIR/home/fortinet/bin

# Copy devcli postinstall template
cat $FABRIC_HOME/modules/debk3s_osscalico_noSNAT_postinst | sed \
  -e 's/INSTALL_CHROME=0/INSTALL_CHROME=1/g' \
  -e 's/INSTALL_MARKTEXT=0/INSTALL_MARKTEXT=1/g' \
  -e 's/INSTALL_ANSIBLE=0/INSTALL_ANSIBLE=1/g' \
  -e 's/KUBECTL_CLIENT=0/KUBECTL_CLIENT=1/g'                                                      >  $BUILDDIR/fortipoc/postinst

echo -e "\necho \"=> Deploy Applications to k3s\""                                                >> $BUILDDIR/fortipoc/postinst
echo -e "echo \"10.2.2.100 debcli\" >> /etc/hosts"                                                >> $BUILDDIR/fortipoc/postinst

echo -e “\necho \"=> Copy kubeconfig file to debcli\n""                                           >> $BUILDDIR/fortipoc/postinst
echo -e "scp /home/fortinet/.kube/config fortinet@debcli:/home/fortinet/.kube/config"             >> $BUILDDIR/fortipoc/postinst

echo -e "\n# Deploy Applications to k3s\""                                                        >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-echoserver-ingress.sh > /dev/null 2>&1\""   >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-edb-ingress.sh > /dev/null 2>&1\""          >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-globex-ingress.sh > /dev/null 2>&1\""       >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-apex-ingress.sh > /dev/null 2>&1\""         >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-acme-ingress.sh > /dev/null 2>&1\""         >> $BUILDDIR/fortipoc/postinst
echo -e "su - fortinet -c \"/home/fortinet/bin/deploy-toolbox-ingress.sh > /dev/null 2>&1\""      >> $BUILDDIR/fortipoc/postinst

echo -e "\necho \"=> change the default router\""                                                 >> $BUILDDIR/fortipoc/postinst
echo -e "\n# change the default router\""                                                         >> $BUILDDIR/fortipoc/postinst
echo -e "ip route del default"                                                                    >> $BUILDDIR/fortipoc/postinst
echo -e "ip route add default via 10.1.1.1 dev ens3"                                              >> $BUILDDIR/fortipoc/postinst

