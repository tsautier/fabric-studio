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

export APP_ECHOSERVER_DOCKER=1
export APP_EDB_DOCKER=1
export APP_GLOBEX_DOCKER=1
export APP_APEX_DOCKER=1
export APP_ACME_DOCKER=1

# Copy Scripts
[ $APP_ECHOSERVER_DOCKER -eq 1 ] && cp $FABRIC_HOME/k3s/deploy-echoserver-docker.sh $BUILDDIR/home/fortinet/bin
[ $APP_EDB_DOCKER -eq 1 ]        && cp $FABRIC_HOME/k3s/deploy-edb-docker.sh        $BUILDDIR/home/fortinet/bin
[ $APP_GLOBEX_DOCKER -eq 1 ]     && cp $FABRIC_HOME/k3s/deploy-globex-docker.sh     $BUILDDIR/home/fortinet/bin
[ $APP_APEX_DOCKER -eq 1 ]       && cp $FABRIC_HOME/k3s/deploy-apex-docker.sh       $BUILDDIR/home/fortinet/bin
[ $APP_ACME_DOCKER -eq 1 ]       && cp $FABRIC_HOME/k3s/deploy-acme-docker.sh       $BUILDDIR/home/fortinet/bin

# Copy Certificate fikes
[ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet

# Copy devwsx postinstall template
cat $FABRIC_HOME/modules/debwsx_postinst | sed \
  -e "s/APP_ECHOSERVER_DOCKER=0/APP_ECHOSERVER_DOCKER=$APP_ECHOSERVER_DOCKER/g" \
  -e "s/APP_EDB_DOCKER=0/APP_EDB_DOCKER=$APP_EDB_DOCKER/g" \
  -e "s/APP_GLOBEX_DOCKER=0/APP_GLOBEX_DOCKER=$APP_GLOBEX_DOCKER/g" \
  -e "s/APP_APEX_DOCKER=0/APP_APEX_DOCKER=$APP_APEX_DOCKER/g" \
  -e "s/APP_ACME_DOCKER=0/APP_ACME_DOCKER=$APP_ACME_DOCKER/g"                                      >  $BUILDDIR/fortipoc/postinst

# Copy Message of the Day
[ -f $DEMOPATH/files/etc/motd ] && cp $DEMOPATH/files/etc/motd $BUILDDIR/etc/motd

# Add Application testing to motd
if [ $APP_ECHOSERVER_DOCKER -eq 1 -o $APP_EDB_DOCKER -eq 1 -o \
     $APP_GLOBEX_DOCKER -eq 1 -o $APP_APEX_DOCKER -eq 1 -o $APP_ACME_DOCKER -eq 1 ]; then

  echo " ▪ Veriy Kubernetes Deployment"                                                                                   >> $BUILDDIR/etc/motd
  echo "   => kubectl get ns"                                                                                             >> $BUILDDIR/etc/motd
  echo "   => kubectl -n toolbox get pods,svc,ingress,secret"                                                             >> $BUILDDIR/etc/motd
  echo ""                                                                                                                 >> $BUILDDIR/etc/motd

  echo " ▪ Test if application is reachable over the kubernetes ingress"                                                  >> $BUILDDIR/etc/motd
  CACERT="--cacert /home/fortinet/cert/fortidemo/ca.crt"
  [ $APP_ECHOSERVER_DOCKER -eq 1 ] && echo "   => curl http://localhost:8084       # ECHO Server"                         >> $BUILDDIR/etc/motd
  [ $APP_EDB_DOCKER -eq 1 ]        && echo "   => curl http://localhost:8080       # EmployeeDB Application"              >> $BUILDDIR/etc/motd
  [ $APP_GLOBEX_DOCKER -eq 1 ]     && echo "   => curl http://localhost:8081       # GLOBEX Home Page"                    >> $BUILDDIR/etc/motd
  [ $APP_APEX_DOCKER -eq 1 ]       && echo "   => curl http://localhost:8082       # APEX Home Page"                      >> $BUILDDIR/etc/motd
  [ $APP_ACME_DOCKER -eq 1 ]       && echo "   => curl http://localhost:8083       # ACME Home Page"                      >> $BUILDDIR/etc/motd
  echo ""                                                                                                                 >> $BUILDDIR/etc/motd
fi

