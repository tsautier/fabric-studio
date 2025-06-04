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
 
# --- SOFTWARE INSTALLATION ---
export KUBECTL_CLIENT=1
export INSTALL_CHROME=1
export INSTALL_MARKTEXT=1
export INSTALL_ANSIBLE=0
export DBEAVER_CE=1

# --- APPLICATION SETTINGS ---
export APP_ECHOSERVER_INGRESS=1
export APP_EDB_INGRESS=0
export APP_GLOBEX_INGRESS=0
export APP_APEX_INGRESS=0
export APP_ACME_INGRESS=0
export APP_TOOLBOX_INGRESS=1

# Copy Certificate fikes
[ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet

# Generate Documentation link for Chrome Browser
#echo "https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/${demo}/README.md" > $BUILDDIR/url
echo "file:///home/fortinet/html/index.html" > $BUILDDIR/url

# Copy devcli postinstall template
mkdir -p $BUILDDIR/fortipoc && cat $FABRIC_HOME/modules/debcli_postinst | sed \
  -e "s/INSTALL_CHROME=0/INSTALL_CHROME=$INSTALL_CHROME/g" \
  -e "s/INSTALL_MARKTEXT=0/INSTALL_MARKTEXT=$INSTALL_MARKTEXT/g" \
  -e "s/INSTALL_ANSIBLE=0/INSTALL_ANSIBLE=$INSTALL_ANSIBLE/g" \
  -e "s/KUBECTL_CLIENT=0/KUBECTL_CLIENT=$KUBECTL_CLIENT/g" \
  -e "s/DBEAVER_CE=0/DBEAVER_CE=$DBEAVER_CE/g"                                                                            >  $BUILDDIR/fortipoc/postinst

# Copy Message of the Day
[ -f $DEMOPATH/files/etc/motd ] && cp $DEMOPATH/files/etc/motd $BUILDDIR/etc/motd

if [ $KUBECTL_CLIENT -eq 1 ]; then
  echo " ▪ Veriy Kubernetes Deployment"                                                                                   >> $BUILDDIR/etc/motd
  echo "   => kubectl get ns"                                                                                             >> $BUILDDIR/etc/motd
  echo "   => kubectl -n toolbox get pods,svc,ingress,secret"                                                             >> $BUILDDIR/etc/motd
  echo ""                                                                                                                 >> $BUILDDIR/etc/motd
fi

# Add Application testing to motd
if [ $APP_ECHOSERVER_INGRESS -eq 1 -o $APP_EDB_INGRESS -eq 1 -o $APP_TOOLBOX_INGRESS -eq 1 -o \
     $APP_GLOBEX_INGRESS -eq 1 -o $APP_APEX_INGRESS -eq 1 -o $APP_ACME_INGRESS -eq 1 ]; then

  echo " ▪ Test if application is reachable over the kubernetes ingress"                                                  >> $BUILDDIR/etc/motd
  CACERT="--cacert /home/fortinet/cert/fortidemo/ca.crt"
  [ $APP_ECHOSERVER_INGRESS -eq 1 ] && echo "   => curl https://echoserver.apps-int.fabric-studio.fortidemo.ch $CACERT"   >> $BUILDDIR/etc/motd
  [ $APP_EDB_INGRESS -eq 1 ]        && echo "   => curl https://edb.apps-int.fabric-studio.fortidemo.ch $CACERT"          >> $BUILDDIR/etc/motd
  [ $APP_GLOBEX_INGRESS -eq 1 ]     && echo "   => curl https://globex.apps-int.fabric-studio.fortidemo.ch $CACERT"       >> $BUILDDIR/etc/motd
  [ $APP_APEX_INGRESS -eq 1 ]       && echo "   => curl https://apex.apps-int.fabric-studio.fortidemo.ch $CACERT"         >> $BUILDDIR/etc/motd
  [ $APP_ACME_INGRESS -eq 1 ]       && echo "   => curl https://acme.apps-int.fabric-studio.fortidemo.ch $CACERT"         >> $BUILDDIR/etc/motd
  [ $APP_TOOLBOX_INGRESS -eq 1 ]    && echo "   => curl https://toolbox.apps-int.fabric-studio.fortidemo.ch $CACERT"      >> $BUILDDIR/etc/motd
  echo ""                                                                                                                 >> $BUILDDIR/etc/motd
fi

[ -f $DEMOPATH/files/etc/motd_dev ] && cat $DEMOPATH/files/etc/motd_dev >> $BUILDDIR/etc/motd

# Copy Demo Guide and HTML
[ $INSTALL_MARKTEXT -eq 1 ] && cp -r $DEMOPATH/files/doc                   $BUILDDIR/home/fortinet
[ $INSTALL_CHROME -eq 1 ]   && cp -r $DEMOPATH/files/html                  $BUILDDIR/home/fortinet
[ $INSTALL_ANSIBLE -eq 1 ]  && cp -r $DEMOPATH/files/ansible               $BUILDDIR/home/fortinet

