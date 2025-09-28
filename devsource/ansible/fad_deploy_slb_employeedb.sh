#!/bin/bash
# ============================================================================================
# File: ........: fad_deploy_slb_employeedb.sh
# Demo Package .: fortiadc-slb-employdb-ansible
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Ansible
# Description ..: Deploy SLB on FortiADC with Ansible
# ============================================================================================
#fortinet.fortiadc                        1.3.0  
#fortinet.fortimanager                    2.7.0  
#fortinet.fortios                         2.3.8  

# Resolve the script's directory, handling symlinks if possible
DEMOPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)

APPNAME="employeedb"
APPPORT="8080"
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
VS_IP_ADDRESS=10.2.1.115
DOMAIN=apps.fortidemo.net
CERTDIR=$HOME/cert/fortidemo
EMPLOYEEDB_CERTIFICATE=$CERTDIR/k3s-apps-external.crt
EMPLOYEEDB_PROVATE_KEY=$CERTDIR/k3s-apps-external.key
TMPDIR=/tmp

[ -f /home/fortinet/ansible/functions ] && source  /home/fortinet/ansible/functions

getObject() {
  local NAMESPACE="$1"
  local OBJ="$2"
  local KEY="$3"
  kubectl -n $NAMESPACE get $OBJ -o jsonpath="{.items[?(@.metadata.name==\"$KEY\")].metadata.name}" | grep -q "$KEY"
}

genTrafficDocker() {
  st1=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fortinet@10.1.1.211 -n "docker logs edb" 2>/dev/null | grep -c "GET \"/actuator")
  st2=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fortinet@10.1.1.212 -n "docker logs edb" 2>/dev/null | grep -c "GET \"/actuator")
  st3=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fortinet@10.1.1.213 -n "docker logs edb" 2>/dev/null | grep -c "GET \"/actuator")

  messageLineIntendDemos
  ls1=0; ls2=0; ls3=0; cnt=1
  while [ $cnt -le 10 ]; do
    curl https://${APPNAME}.${DOMAIN}/actuator/health > /dev/null 2>&1
    cn1=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fortinet@10.1.1.211 -n "docker logs edb" 2>/dev/null | grep -c "GET \"/actuator")
    cn2=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fortinet@10.1.1.212 -n "docker logs edb" 2>/dev/null | grep -c "GET \"/actuator")
    cn3=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fortinet@10.1.1.213 -n "docker logs edb" 2>/dev/null | grep -c "GET \"/actuator")

    let tt1=cn1-st1
    let tt2=cn2-st2
    let tt3=cn3-st3

    tx1=$(printf "%02d\n" $tt1)
    tx2=$(printf "%02d\n" $tt2)
    tx3=$(printf "%02d\n" $tt3)
    hdr=$(printf "%03d\n" $cnt)

    [ $tt1 -eq $ls1 ] && tx1="${ip1} [${tx1}]" || tx1="\033[32m${ip1} [${tx1}]\033[0m"
    [ $tt2 -eq $ls2 ] && tx2="${ip2} [${tx2}]" || tx2="\033[32m${ip2} [${tx2}]\033[0m"
    [ $tt3 -eq $ls3 ] && tx3="${ip3} [${tx3}]" || tx3="\033[32m${ip3} [${tx3}]\033[0m"

    b=$(printf "%02d\n" $ttb)
    g=$(printf "%02d\n" $ttg)

    echo -e "     [${hdr}] https://${APPNAME}.${DOMAIN}/actuator/health                       $tx1   $tx2   $tx3"

    ls1=$tt1; ls2=$tt2; ls3=$tt3
    let cnt=cnt+1
    sleep 2
  done
  messageLineIntendDemos
  emptyLine
}

genTrafficKubernetes() {
  st1=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-01 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
  st2=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-02 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
  st3=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-03 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")

  messageLineIntendDemos
  ls1=0; ls2=0; ls3=0; cnt=1
  while [ $cnt -le 10 ]; do
    curl http://$VS_IP_ADDRESS/actuator/health > /dev/null 2>&1
    cn1=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-01 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
    cn2=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-02 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
    cn3=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-03 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
  
    let tt1=cn1-st1
    let tt2=cn2-st2
    let tt3=cn3-st3
  
    tx1=$(printf "%02d\n" $tt1)
    tx2=$(printf "%02d\n" $tt2)
    tx3=$(printf "%02d\n" $tt3)
    hdr=$(printf "%03d\n" $cnt)
  
    [ $tt1 -eq $ls1 ] && tx1="${ip1} [${tx1}]" || tx1="\033[32m${ip1} [${tx1}]\033[0m"
    [ $tt2 -eq $ls2 ] && tx2="${ip2} [${tx2}]" || tx2="\033[32m${ip2} [${tx2}]\033[0m"
    [ $tt3 -eq $ls3 ] && tx3="${ip3} [${tx3}]" || tx3="\033[32m${ip3} [${tx3}]\033[0m"
  
    b=$(printf "%02d\n" $ttb)
    g=$(printf "%02d\n" $ttg)
  
    echo -e "     [${hdr}] http://employeedb-slb.fortidemo.ch/actuator/health                       $tx1   $tx2   $tx3"
  
    ls1=$tt1; ls2=$tt2; ls3=$tt3
    let cnt=cnt+1
    sleep 2
  done
  messageLineIntendDemos
  emptyLine
}

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '                             _____          _   _    _    ____   ____                 '
echo '                            |  ___|__  _ __| |_(_)  / \  |  _ \ / ___|                '
echo '                            | |_ / _ \|  __| __| | / _ \ | | | | |                    '
echo '                            |  _| (_) | |  | |_| |/ ___ \| |_| | |___                 '
echo '                            |_|  \___/|_|   \__|_/_/   \_\____/ \____|                '
echo '                    _              _ _     _        ____                              '
echo '                   / \   _ __  ___(_) |__ | | ___  |  _ \  ___ _ __ ___   ___         '
echo '                  / _ \ |  _ \/ __| |  _ \| |/ _ \ | | | |/ _ \  _   _ \ / _ \        '
echo '                 / ___ \| | | \__ \ | |_) | |  __/ | |_| |  __/ | | | | | (_) |       '
echo '                /_/   \_\_| |_|___/_|_.__/|_|\___| |____/ \___|_| |_| |_|\___/        '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '             Configure an Server Loadbalancer on a FortiADC with Ansible Playbook     '
echo '                                  by Sacha Dubois, Fortinet Inc                       '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

ip1=10.1.1.211
ip2=10.1.1.212
ip3=10.1.1.213

nc -w 1 -z $ip1 $APPPORT && ipstat1="up" || ipstat1="down"
nc -w 1 -z $ip2 $APPPORT && ipstat2="up" || ipstat2="down"
nc -w 1 -z $ip3 $APPPORT && ipstat3="up" || ipstat3="down"

echo ""
prtText "The EmployeeDB Application has been already deployed on the the Backend Servers."
prtText "Open WebBrowser and verify the EmployeeDB Backend"
echo "     => http://$ip1:$APPPORT ($ipstat1)"
echo "     => http://$ip2:$APPPORT ($ipstat2)"
echo "     => http://$ip3:$APPPORT ($ipstat3)"
echo ""
echo -e "     Press 'return' to continue \c\b"; read x
echo ""

prtHead "Create a Ansible Playbook"
prtText "The Playbook creates a Virtual Server, Real Server Pool with four Members. We create at first a values file"
prtText "and add the IP adresses of the four applications as Real Server Pool"

wt1=1; wt2=1; wt3=1
cat <<EOF > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml
# Real Server Pool
pool_name: employeedb
         
# Virtual Server Configuration
virtual_server_name: ws-employeedb-fad-vi
virtual_server_ip: $VS_IP_ADDRESS
virtual_server_interface: port1
virtual_server_port: 443
virtual_server_type: http
iptype: ipv4
vdom: root
         
# Certificate Configuration
ssl_cert: $EMPLOYEEDB_CERTIFICATE
ssl_key: $EMPLOYEEDB_PROVATE_KEY
local_cert_group: EMPLOYEEDB_CERT_GROUP
client_ssl_profile: LB_CLIENT_SSL_EMPLOYEEDB
         
# Real Server Pool Members
real_servers:
  - name: rs_employeedb1
    id: 1
    port: 8080
    status: enable
    ip: ${ip1}
    weight: ${wt1}
  - name: rs_employeedb2
    id: 2
    port: 8080
    status: enable
    ip: ${ip2}
    weight: ${wt2}
  - name: rs_employeedb3
    id: 3
    port: 8080
    status: enable
    ip: ${ip3}
    weight: ${wt3}
EOF
execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml"

prtHead "Create a protected ansible-vault password in your home directory"
slntCmd "echo \"F0rt!net\" > $HOME/.ansible/vault_password"
slntCmd "chmod 600 $HOME/.ansible/vault_password"
execCmd "ls -la \$HOME/.ansible/vault_password"

#prtText "Encrypt credentials with ansible-vault"
prtText "Create a vault file containing the 'fortiadc_password' password in clear text"

echo "# vault.yaml"                              >  $TMPDIR/vault.yaml 
echo "fortiadc_password: \"F0rt!net\""           >> $TMPDIR/vault.yaml
execCat "$TMPDIR/vault.yaml"

prtText "Encrypt the vault.yaml with ansible-vault"
slntCmd "ansible-vault encrypt /tmp/vault.yaml --vault-password-file \$HOME/.ansible/vault_password"
messageLineIntendDemos
echo "     Encryption successful"
messageLineIntendDemos
echo ""

execCat "$TMPDIR/vault.yaml"

prtHead "Create an Inventory file for the target hosts and credentials"
prtText "We are using the encrypted 'fortiadc_password' we have just created in the /tmp/vault.yaml"
cat <<EOF > /tmp/inventory
[fortiadcs]
fortiadc ansible_host=10.2.1.3 ansible_user="admin" ansible_password="{{ fortiadc_password }}"
         
[fortiadcs:vars]
ansible_network_os=fortinet.fortiadc.fadcos
ansible_httpapi_use_ssl=yes
ansible_httpapi_validate_certs=no
ansible_httpapi_port=443
EOF
execCat "$TMPDIR/inventory"

# Extract notBefore and notAfter dates
not_before=$(openssl x509 -in $EMPLOYEEDB_CERTIFICATE -noout -dates | grep 'notBefore=' | cut -d'=' -f2)
not_after=$(openssl x509 -in $EMPLOYEEDB_CERTIFICATE -noout -dates | grep 'notAfter=' | cut -d'=' -f2)

# Convert to Unix time (Linux/GNU date)
not_before_unix=$(date -d "$not_before" +%s)
not_after_unix=$(date -d "$not_after" +%s)

current_time=$(date +%s)
if [ "$not_after_unix" -lt "$current_time" ]; then
    echo "ERROR: The SSL/TLS Certificate for employeedb.fortidemo.sh) has expired."
    echo "       Please regenerate the Certificate:"
    echo "       => cd $HOME/workspace/certbot"
    echo "       => ./genCertificate_employeedb_fortidemo.sh"
    exit
fi

prtHead "Let's create an Ansible Playbook to configure SSL/TLS on the Virtual Server"
prtText "At first, we create a variable file again"

wt1=1; wt2=1; wt3=1
cat $DEMOPATH/playbook/fortiadc-lb-vars-${APPNAME}.yaml | sed \
  -e "s+XXX1XXX+${EMPLOYEEDB_CERTIFICATE}+g" -e "s+XXX2XXX+${EMPLOYEEDB_PROVATE_KEY}+g" \
  > $TMPDIR/fortiadc-lb-vars-${APPNAME}-ssl.yaml

cp $DEMOPATH/playbook/fortiadc-lb-config.yaml /tmp
cp $DEMOPATH/playbook/fortiadc-lb-delete.yaml /tmp
execCat "$TMPDIR/fortiadc-lb-config.yaml"

prtHead "Run the Ansible Playbook (/tmp/fortiadc-lb-config.yaml)"
prtText "The Playbook creates am Virtual Server (employeedb-ssl) for TLS/SSL. Therefor we need to create a"
prtText "Client SSL Profile containing the Certificate with a Cert Group and a local Certificate."
echo -e "     => ansible-playbook /tmp/fortiadc-lb-config.yaml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yaml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
messageLineIntendDemos

ansible-playbook /tmp/fortiadc-lb-config.yaml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yaml" \
 --vault-password-file $HOME/.ansible/vault_password -v 2>/dev/null | python3 $DEMOPATH/scripts/indent_output.py

prtHead "Now let's test the new Virtual Server"
prtText "Open WebBrowser and verify the deployment"
echo "     => https://${APPNAME}.${DOMAIN}"
echo "     => https://${APPNAME}.${DOMAIN}/actuator/health"
echo ""

#########################################################################################################################
###################### TEST: Demonstration how load is spread across real server pool members ###########################
#########################################################################################################################
ret=$(askQustion "Would you like to see how the Load Balancer is spreading traffic across the instances ? <y/n>:")
[ "$ret" == "y" ] && genTrafficDocker

#########################################################################################################################
############################## TEST: change weight assigned to a real server pool member ################################
#########################################################################################################################
ret=$(askQustion "Would you like to see how different weighting changes the balancing behaviour ? <y/n>:")
if [ "$ret" == "y" ]; then 
  wt1=1; wt2=3; wt3=5
  cat $DEMOPATH/playbook/fortiadc-lb-vars-${APPNAME}.yaml | sed \
    -e "s/XXXIP1XXX/${ip1}/g" -e "s/XXXIP2XXX/${ip2}/g" \
    -e "s/XXXIP3XXX/${ip3}/g" -e "s/YYY1YYY/${wt1}/g" \
    -e "s/YYY2YYY/${wt2}/g" -e "s/YYY3YYY/${wt3}/g" \
    > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml

  emptyLine
  prtText "We are going to modify the configuration that each Member gets the following traffic weighing (Member-1: $wt1, Member-2, $wt2 and Member-3: $wt3)"
  execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml"

  prtText "To only update the Real Server Pool Members, we create an Real Server Pool Member Ansible Playbook"
  cp $DEMOPATH/playbook/fortiadc-lb-member-update.yaml /tmp

  execCat "$TMPDIR/fortiadc-lb-member-update.yaml"

  prtText "Configure the Server Load Balancer with the Ansible Playbook"
  echo -e "     => ansible-playbook $TMPDIR/fortiadc-lb-member-update.yaml \\"
  echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yaml\" \\"
  echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
  messageLineIntendDemos

  ansible-playbook $TMPDIR/fortiadc-lb-member-update.yaml \
    -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yaml" \
   --vault-password-file $HOME/.ansible/vault_password | python3 $DEMOPATH/scripts/indent_output.py
  
  prtText "Let's generate again some traffic and watch the balancing"

  genTrafficDocker
fi

#########################################################################################################################
################################ TEST: How Load is spreading with one disabled Member ###################################
#########################################################################################################################
ret=$(askQustion "Would you like to see what happens when we disable a link ? <y/n>:")
if [ "$ret" == "y" ]; then
  wt1=1; wt2=1; wt3=1
  cat $DEMOPATH/playbook/fortiadc-lb-vars-${APPNAME}.yaml | sed \
    -e '/name: rs_employeedb2/,/weight: YYY2YYY/ s/status: enable/status: disable/g' \
    -e "s/XXXIP1XXX/${ip1}/g" -e "s/XXXIP2XXX/${ip2}/g" \
    -e "s/XXXIP3XXX/${ip3}/g" -e "s/YYY1YYY/${wt1}/g" \
    -e "s/YYY2YYY/${wt2}/g" -e "s/YYY3YYY/${wt3}/g" \
    > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml
    
  emptyLine
  prtText "We are going to modify the configuration that each Member gets the following traffic weighing (Member-1: $wt1, Member-2, $wt2 and Member-3: $wt3)"
  execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml"
    
  prtText "To only update the Real Server Pool Members, we create an Real Server Pool Member Ansible Playbook"
  cp $DEMOPATH/playbook/fortiadc-lb-member-update.yaml /tmp
    
  execCat "$TMPDIR/fortiadc-lb-member-update.yaml"
    
  prtText "Configure the Server Load Balancer with the Ansible Playbook"
  echo -e "     => ansible-playbook $TMPDIR/fortiadc-lb-member-update.yaml \\"
  echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yaml\" \\"
  echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
  messageLineIntendDemos

  ansible-playbook $TMPDIR/fortiadc-lb-member-update.yaml \
    -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yaml" \
   --vault-password-file $HOME/.ansible/vault_password | python3 $DEMOPATH/scripts/indent_output.py
  
  prtText "Let's generate again some traffic and watch the balancing"

  genTrafficDocker
fi

messageLineIntendDemos
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
messageLineIntendDemos

exit
