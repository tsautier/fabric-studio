#!/bin/bash
# ============================================================================================
# File: ........: edb_restapi_insert_faulty_data.sh
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Application Protection
# Description ..: Cleanup Test Date
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

echo -e "\n# Faulty Email Address"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" \
  -d '{"firstName":"Alice","lastName":"Smith","email":"alicexexample.com"}' \
  ${URL}/${API}/employees 2>/dev/null | jq -r

curl -k -X GET -H "Content-Type: application/json" \
  -H "api_key: $APIKEY" \
  ${URL}/${API}/employees/test 2>/dev/null | jq -r

#echo "${URL}/${API}/employees"
