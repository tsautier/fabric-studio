#!/bin/bash
# ============================================================================================
# File: ........: edb_restapi_insert_malicious_data.sh
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Application Protection
# Description ..: Testing inserting Malicious data
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

echo -e "\n# XSS (Cross-Site Scripting)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data00.json \
  ${URL}/${API}/employee 2>/dev/null

echo -e "\n# XSS (Cross-Site Scripting)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data01.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# SQL Injection (Authentication Bypass)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data02.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# SQL Injection (Database Manipulation)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data03.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# SQL Injection (Login Bypass)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data04.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# XSS (Stored XSS via Image)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data05.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# Command Injection (Executing System Commands)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data06.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# XSS (SVG Payload)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data07.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# SQL Injection (Extracting User Credentials)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data08.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# Clickjacking (JavaScript Injection via Link) "
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data09.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

echo -e "\n# SQL Injection (Wildcard Comment Bypass)"
curl -k -X POST -H "Content-Type: application/json" -H "api_key: $APIKEY" -d @files/data10.json \
  ${URL}/${API}/employee 2>/dev/null | jq -r

