#!/bin/bash
# ============================================================================================
# File: ........: edb_restapi_insert_regular_array_data.sh
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Application Protection
# Description ..: Test Inserting regular Data in one lift as Array of Elements
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

# Cleanup
x=$(curl https://edb.apps.fortidemo.net/api/employees 2>/dev/null | jq length)
if [ $x -ne 0 ]; then 
  prtHead "Cleaning up $x records in the database"
  slntCmd "curl -X DELETE -H \"Content-Type: application/json\" -H \"api_key: $APIKEY\" ${URL}/${API}/employees 2>/dev/null"
fi

echo "TDHHOME:$TDHHOME"
# Generate Fake USers
prtHead "Generate Test Data (12000) records"
[ ! -f /tmp/random_users.json ] && python3 $TDHHOME/scripts/users.py
execCmd "jq '.[0:3]' /tmp/random_users.json"
execCmd "jq length /tmp/random_users.json"

prtHead "Add 12000 EmployeeDB Records for ML training"
execCmd "curl -X POST -H \"Content-Type: application/json\" \\
             -d \"@/tmp/random_users.json\" \\
             -H \"api_key: $APIKEY\" \\
             ${URL}/${API}/employees 2>/dev/null | jq -r '\"Elements added: \\(. | length)\"'"

