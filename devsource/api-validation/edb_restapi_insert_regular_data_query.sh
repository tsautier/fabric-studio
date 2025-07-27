#!/bin/bash
# ============================================================================================
# File: ........: edb_restapi_insert_regular_data_query.sh
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Application Protection
# Description ..: Test Inserting regular Data
# ============================================================================================

# Resolve the script's directory, handling symlinks if possible
TDHHOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)

export TMPDIR=/tmp
export SERVER=edb.apps.fortidemo.net
export EDB_APIKEY_USER="a3ZEqiT3KzAPiupVt0mwKx0fQaLL000b9t8L9THf"
export EDB_APIKEY_ADMIN="VfqRm2TWyMri82HaMO20r2nrjtG1wLykUNg57HvP"
export APIKEY=$EDB_APIKEY_ADMIN

[ -f $TDHHOME/functions ] && . $TDHHOME/functions

URL="https://edb.apps.fortidemo.net"
API="api"

# Generating test data
[ ! -f /tmp/random_users.json ] && python3 $TDHHOME/scripts/users.py

# Cleanup
x=$(curl https://edb.apps.fortidemo.net/api/employees 2>/dev/null | jq length)
if [ $x -ne 0 ]; then
  prtHead "Cleaning up $x records in the database"
  slntCmd "curl -X DELETE -H \"Content-Type: application/json\" -H \"api_key: $APIKEY\" ${URL}/${API}/employees 2>/dev/null"
fi

prtText ""
prtHead "Inserting 12000 records on ${URL}/${API}/employee"
prtText "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
# adding users
i=1
for n in $(cat /tmp/random_users.json | jq -r '.[] | .firstName + ":" + .lastName + ":" + .email'); do

  fst=$(echo $n | awk -F: '{ print $1 }')
  lst=$(echo $n | awk -F: '{ print $2 }')
  eml=$(echo $n | awk -F: '{ print $3 }')

  id=$(curl -k -X POST -H "Content-Type: application/json" \
    -d "{\"firstName\":\"$fst\",\"lastName\":\"$lst\",\"email\":\"$eml\"}" \
    -H "api_key: $APIKEY" \
    ${URL}/${API}/employee 2>/dev/null | jq -r '.id')

    emlsuf=$(echo $eml | awk -F'@' '{ print $NF}')
    eml="${fst}.${lst}@$emlsuf"

  curl -X PUT -H "Content-Type: application/json" \
    -d "{\"firstName\":\"$fst\",\"lastName\":\"$lst\",\"email\":\"$eml\"}" \
    -H "api_key: $APIKEY" \
    ${URL}/${API}/employee?id=$id >/dev/null 2>&1

  curl -X GET -H "Content-Type: application/json" \
    -H "api_key: $APIKEY" \
    ${URL}/${API}/employee?id=$id >/dev/null 2>&1

  curl -X DELETE -H "Content-Type: application/json" \
    -H "api_key: $APIKEY" \
    ${URL}/${API}/employee?id=$id >/dev/null 2>&1

  let i=i+1
  #echo -e "     $i \b\b\b\b\b\b\b\c"
  printf "\b\b\b\b\b\b\b\b\b     %-00000d" $i
done

echo "$1 users added"

curl -k -X GET -H "Content-Type: application/json" \
     -H "api_key: $APIKEY" \
${URL}/${API}/employees 2>/dev/null | jq -r


exit
