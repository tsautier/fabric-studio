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

export APP_ECHOSERVER_INGRESS=1
export APP_EDB_INGRESS=1
export APP_GLOBEX_INGRESS=1
export APP_APEX_INGRESS=1
export APP_ACME_INGRESS=1
export APP_TOOLBOX_INGRESS=1
export PROXY_DEFAULT_ROUTER=1

# Copy Certificate files
[ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet

# Copy Scripts
[ $APP_ECHOSERVER_INGRESS -eq 1 ] && cp $FABRIC_HOME/k3s/deploy-echoserver-ingress.sh $BUILDDIR/home/fortinet/bin
[ $APP_EDB_INGRESS -eq 1 ]        && cp $FABRIC_HOME/k3s/deploy-edb-ingress.sh        $BUILDDIR/home/fortinet/bin
[ $APP_GLOBEX_INGRESS -eq 1 ]     && cp $FABRIC_HOME/k3s/deploy-globex-ingress.sh     $BUILDDIR/home/fortinet/bin
[ $APP_APEX_INGRESS -eq 1 ]       && cp $FABRIC_HOME/k3s/deploy-apex-ingress.sh       $BUILDDIR/home/fortinet/bin
[ $APP_ACME_INGRESS -eq 1 ]       && cp $FABRIC_HOME/k3s/deploy-acme-ingress.sh       $BUILDDIR/home/fortinet/bin
[ $APP_TOOLBOX_INGRESS -eq 1 ]    && cp $FABRIC_HOME/k3s/deploy-toolbox-ingress.sh    $BUILDDIR/home/fortinet/bin

# Copy Message of the Day
[ -f $DEMOPATH/files/etc/motd ] && cp $DEMOPATH/files/etc/motd $BUILDDIR/etc/motd

# Add Application testing to motd
if [ $APP_ECHOSERVER_INGRESS -eq 1 -o $APP_EDB_INGRESS -eq 1 -o $APP_TOOLBOX_INGRESS -eq 1 -o \
     $APP_GLOBEX_INGRESS -eq 1 -o $APP_APEX_INGRESS -eq 1 -o $APP_ACME_INGRESS -eq 1 ]; then

  echo " ▪ Veriy Kubernetes Deployment"                                                                                   >> $BUILDDIR/etc/motd
  echo "   => kubectl get ns"                                                                                             >> $BUILDDIR/etc/motd
  echo "   => kubectl -n toolbox get pods,svc,ingress,secret"                                                             >> $BUILDDIR/etc/motd
  echo ""                                                                                                                 >> $BUILDDIR/etc/motd

  echo " ▪ Test if application is reachable over the kubernetes ingress"                                                  >> $BUILDDIR/etc/motd
  CACERT="--cacert /home/fortinet/cert/fortidemo/ca.crt"
  [ $APP_ECHOSERVER_INGRESS -eq 1 ] && echo "   => curl https://echoserver.apps-int.fortidemo.net $CACERT"                >> $BUILDDIR/etc/motd
  [ $APP_EDB_INGRESS -eq 1 ]        && echo "   => curl https://edb.apps-int.fortidemo.net $CACERT"                       >> $BUILDDIR/etc/motd
  [ $APP_GLOBEX_INGRESS -eq 1 ]     && echo "   => curl https://globex.apps-int.fortidemo.net $CACERT"                    >> $BUILDDIR/etc/motd
  [ $APP_APEX_INGRESS -eq 1 ]       && echo "   => curl https://apex.apps-int.fortidemo.net $CACERT"                      >> $BUILDDIR/etc/motd
  [ $APP_ACME_INGRESS -eq 1 ]       && echo "   => curl https://acme.apps-int.fortidemo.net $CACERT"                      >> $BUILDDIR/etc/motd
  [ $APP_TOOLBOX_INGRESS -eq 1 ]    && echo "   => curl https://toolbox.apps-int.fortidemo.net $CACERT"                   >> $BUILDDIR/etc/motd
  echo ""                                                                                                                 >> $BUILDDIR/etc/motd
fi

[ -f $DEMOPATH/files/etc/motd_k3s ] && cat $DEMOPATH/files/etc/motd_k3s >> $BUILDDIR/etc/motd

# Copy devk3s postinstall template
cat $FABRIC_HOME/modules/debk3s_osscalico_noSNAT_postinst | sed \
  -e "s/APP_ECHOSERVER_INGRESS=0/APP_ECHOSERVER_INGRESS=$APP_ECHOSERVER_INGRESS/g" \
  -e "s/APP_EDB_INGRESS=0/APP_EDB_INGRESS=$APP_EDB_INGRESS/g" \
  -e "s/APP_GLOBEX_INGRESS=0/APP_GLOBEX_INGRESS=$APP_GLOBEX_INGRESS/g" \
  -e "s/APP_APEX_INGRESS=0/APP_APEX_INGRESS=$APP_APEX_INGRESS/g" \
  -e "s/APP_ACME_INGRESS=0/APP_ACME_INGRESS=$APP_ACME_INGRESS/g" \
  -e "s/APP_TOOLBOX_INGRESS=0/APP_TOOLBOX_INGRESS=$APP_TOOLBOX_INGRESS/g" \
  -e "s/PROXY_DEFAULT_ROUTER=0/PROXY_DEFAULT_ROUTER=$PROXY_DEFAULT_ROUTER/g"              >  $BUILDDIR/fortipoc/postinst
