#!/bin/bash
# ============================================================================================
# File: ........: edb_restapi_query_params.sh
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Application Protection
# Description ..: Test RestAPI Query Parameters
# ============================================================================================

# Resolve the script's directory, handling symlinks if possible
TDHHOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)

export TMPDIR=/tmp
export SERVER=edb.apps.fortidemo.net
export EDB_APIKEY_USER="a3ZEqiT3KzAPiupVt0mwKx0fQaLL000b9t8L9THf"
export EDB_APIKEY_ADMIN="VfqRm2TWyMri82HaMO20r2nrjtG1wLykUNg57HvP"

[ -f $TDHHOME/functions ] && . $TDHHOME/functions

echo ''
echo '   ____           _      _    ____ ___    ___                          ____                                _                 '
echo '  |  _ \ ___  ___| |_   / \  |  _ \_ _|  / _ \ _   _  ___ _ __ _   _  |  _ \ __ _ _ __ __ _ _ __ ___   ___| |_ ___ _ __      '
echo '  | |_) / _ \/ __| __| / _ \ | |_) | |  | | | | | | |/ _ \  __| | | | | |_) / _  |  __/ _  |  _   _ \ / _ \ __/ _ \  __|     '
echo '  |  _ <  __/\__ \ |_ / ___ \|  __/| |  | |_| | |_| |  __/ |  | |_| | |  __/ (_| | | | (_| | | | | | |  __/ ||  __/ |        '
echo '  |_| \_\___||___/\__/_/   \_\_|  |___|  \__\_\\__,_|\___|_|   \__, | |_|   \__,_|_|  \__,_|_| |_| |_|\___|\__\___|_|        '
echo '                                                               |___/                                                         '
echo '                                                                                         '
echo '                                     RestAPI Calls with customized Query Parameters'
echo '                                               by Sacha Dubois, Fortinet Inc                       '
echo ''

# Cleaning up
curl -X DELETE "https://$SERVER/api/employees" \
             -H "Content-Type: application/json"   \
             -H "api_key: $EDB_APIKEY_ADMIN" > /dev/null 2>&1

# Load Initial Data
curl -X POST "https://edb.apps.fortidemo.net/api/employees" \
             -H "Content-Type: application/json"   \
             -H "api_key: $EDB_APIKEY_ADMIN" \
             -d "[ \
                   { \"firstName\":\"Sacha\", \"lastName\":\"Dubois\", \"email\":\"sdubois@example.com\" }, \
                   { \"firstName\":\"Mike\", \"lastName\":\"Anderson\", \"email\":\"mandersoon@example.com\" }, \
                   { \"firstName\":\"Steven\", \"lastName\":\"Miles\", \"email\":\"smiles@example.com\" }, \
                   { \"firstName\":\"Ron\", \"lastName\":\"Doe\", \"email\":\"rdoe@example.com\" }, \
                   { \"firstName\":\"Julie\", \"lastName\":\"Foxwell\", \"email\":\"jfoxwell@example.com\" } \
                 ]" \
             >/dev/null > /dev/null 2>&1

prtHead "List All EmployeeDB Records"
execCmd "curl -X GET \"https://$SERVER/api/employees\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

prtHead "List All EmployeeDB Records with sortby=id"
execCmd "curl -X GET \"https://$SERVER/api/employees?sort_by=id\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

prtHead "List All EmployeeDB Records with sortby=-id"
execCmd "curl -X GET \"https://$SERVER/api/employees?sort_by=-id\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

prtHead "List All EmployeeDB Records with sortby=lastName"
execCmd "curl -X GET \"https://$SERVER/api/employees?sort_by=lastName\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

prtHead "List All EmployeeDB Records with limit=2"
execCmd "curl -X GET \"https://$SERVER/api/employees?limit=2\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

execCmd "curl -X GET \"https://$SERVER/api/employees?limit=2&offset=2\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

prtHead "List All EmployeeDB Records with limit=a     <- Clearly Wrong parameter"
execCmd "curl -X GET \"https://$SERVER/api/employees?limit=a\" \\
             -H \"Content-Type: application/json\"   \\
             2>/dev/null"

execCmd "curl -X GET \"https://$SERVER/api/employees?limit=a\" \\
             -H \"Content-Type: application/json\"   \\
             -H \"Accept: application/xml\" \\
             2>/dev/null"

execCmd "curl -X GET \"https://$SERVER/api/employees?limit=a\" \\
             -H \"Content-Type: application/json\"   \\
             -H \"Accept: application/json\" \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

             exit


fst="sacha$$"
lst="dubois$$"
eml="sacha$$.Dubois$$@example.com"

prtHead "List EmployeeDB Records"
execCmd "curl -X GET https://$SERVER/api/employees \\
             -H \"Content-Type: application/json\"   \\
             -H \"Accept: application/json\" \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

exit

prtHead "List EmployeeDB Records"
execCmd "curl -X POST https://$SERVER/api/employee \\
             -H \"Content-Type: application/json\"   \\
             -H \"Accept: application/json\" \\
             -d \"{\\\"firstName\\\":\\\"$fst\\\",\\\"lastName\\\":\\\"$lst\\\",\\\"email\\\":\\\"$eml\\\"}\" \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

exit

prtHead "List EmployeeDB Records"
execCmd "curl -X POST https://$SERVER/api/employee \\
             -H \"Content-Type: application/json\"   \\
             -H \"Accept: application/json\" \\
             -d \"{\\\"firstName\\\":\\\"$fst\\\",\\\"lastName\\\":\\\"$lst\\\",\\\"email\\\":\\\"$eml\\\"}\" \\
             2>/dev/null | sed 's/,}/}/' | jq -r"

exit

#  id=$(curl -k -X POST -H "Content-Type: application/json" \
#    -d "{\"firstName\":\"$fst\",\"lastName\":\"$lst\",\"email\":\"$eml\"}" \
#    -H "api_key: $APIKEY" \
#    ${URL}/${API}/employees 2>/dev/null | jq -r '.id')

prtHead "List EmployeeDB Records"
execCmd "curl -X POST https://$SERVER/api/employees \\
             -H \"Content-Type: application/json\"   \\
             -H \"Accept: application/json\" 2>/dev/null | jq -r "

prtHead "DELETE EmployeeDB Records"
execCmd "curl -X DELETE https://$SERVER/api/employee/1 \\n             -H \"Content-Type: application/json\"   \\n             -H \"Accept: application/json\" 2>/dev/null | jq -r "



exit
