#!/bin/bash
# ============================================================================================
# File: ........: fad_delete_slb_employeedb.sh
# Demo Package .: fortiadc-slb-employdb-ansible
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Category .....: VMware Tanzu Data for Postgres
# Description ..: Database Resize (CPU, Memory and Disk) 
# ============================================================================================
# https://postgres-kubernetes.docs.pivotal.io/1-1/update-instances.html

# Resolve the script's directory, handling symlinks if possible
DEMOPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)

export APPNAME="employeedb"
export APPPORT="8080"
export TDH_DEMO_DIR="fortiadc-slb-employdb-ansible"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export VS_IP_ADDRESS=10.1.1.115
export TMPDIR=/tmp

[ -f /home/fortinet/ansible/functions ] && source  /home/fortinet/ansible/functions

getObject() {
  local NAMESPACE="$1"
  local OBJ="$2"
  local KEY="$3"
  kubectl -n $NAMESPACE get $OBJ -o jsonpath="{.items[?(@.metadata.name==\"$KEY\")].metadata.name}" | grep -q "$KEY"
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
echo '                                  by Sacha Dubois, Fprtinet Inc                       '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

wt1=1; wt2=1; wt3=1
cat <<EOF > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml
# Real Server Pool
pool_name: employeedb

# Virtual Server Configuration
virtual_server_name: ws-employeedb-fad-vs
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

prtHead "Let's review the ansible variable file created during the deployment"
execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yaml"

prtHead "To delete the configuaration we need to create a removal Playbook to cleanup the configuration"
execCat "$TMPDIR/fortiadc-lb-delete-ssl.yaml"

prtHead "Delete the Server Load Balancer with the Ansible Playbook"
echo -e "     => ansible-playbook /tmp/fortiadc-lb-delete-ssl.yaml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yaml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
messageLineIntendDemos

ansible-playbook /tmp/fortiadc-lb-delete-ssl.yaml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yaml" \
  --vault-password-file $HOME/.ansible/vault_password | python3 $DEMOPATH/scripts/indent_output.py; ret=$?

if [ $ret -ne 0 ]; then
  echo "ERROR: The ansible playbook failed to remove the deployment, please fix the error and start over"
  exit
else
  rm -f $LOCK_FILE_1
fi

messageLineIntendDemos
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
messageLineIntendDemos

exit
