#!/bin/bash
set -euo pipefail

# author: dbalogh@fortinet.com
# description:  This script adds 10.7.80.20 or fpocrepo.ftnt.lab as repository to Fabric Studio. 
#               it uses SCP to upload the issuer CA cert of the repo server and SSH to apply the
#               configuration to the user's Fabric Studio instance. SSHPASS is required to
#               avoid annoying multi-input of user passwords

# Global variables
# Use FQDN only when 10.7.80.10 is your DNS, otherwise use the IP address of the repo server
REPO_URI="https://10.7.80.20/fabric/prod"
#REPO_URI="https://fpocrepo.ftnt.lab/fabric/prod"
REPO_NAME="Fortinet CH - Prod"
REPO_DESC="The cool stuff only! This repository contains tested templates and firmware for customer demos"

# Certificate file variable
CERT_FILE="rootca01.ftnt.lab.crt"
# CN of the issuer signing cert
CA_CN="rootca01.ftnt.lab"
# Embedded certificate content stored within a variable, will be uploaded to Fabric Studio later
CERT_CONTENT=$(cat <<'EOF'
-----BEGIN CERTIFICATE-----
MIIG1TCCBL2gAwIBAgIIfj6xWAbwx+gwDQYJKoZIhvcNAQELBQAwgZ0xCzAJBgNV
BAYTAkNIMQ8wDQYDVQQIDAZadXJpY2gxEjAQBgNVBAcMCURpZXRsaWtvbjERMA8G
A1UECgwIRm9ydGluZXQxHDAaBgNVBAsME1N5c3RlbXMgRW5naW5lZXJpbmcxGjAY
BgNVBAMMEXJvb3RjYTAxLmZ0bnQubGFiMRwwGgYJKoZIhvcNAQkBFg1pbmZvQGZ0
bnQubGFiMB4XDTI1MDEyNDEwNTAwM1oXDTM1MDEyMjEwNTAwM1owgZ0xCzAJBgNV
BAYTAkNIMQ8wDQYDVQQIDAZadXJpY2gxEjAQBgNVBAcMCURpZXRsaWtvbjERMA8G
A1UECgwIRm9ydGluZXQxHDAaBgNVBAsME1N5c3RlbXMgRW5naW5lZXJpbmcxGjAY
BgNVBAMMEXJvb3RjYTAxLmZ0bnQubGFiMRwwGgYJKoZIhvcNAQkBFg1pbmZvQGZ0
bnQubGFiMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkVb2zg9YNKsC
nI+upAjbFFpsBN8wC9zgI8N+xbn0xYMz9ZgSZwqBxXz10dXI/8C9JUGydYyYQ0v2
JmCreHlXi3dIWqZuFlqo4o227+o8VMWTvSwSHaGCbF3rbWzIj6uCJnJFxdO7DTvj
2tMBjsHQkDjGSh2R5Nh7EmQnwM2OSrLvx0KNJ6NaMzVXAwMrbC9ZrzH0uzwXpWfz
tjmPpDRKRweaNszCruQl+DTaQb8NT3lHaqonalsmlJNF5ORmywtkKrsQnus7G5Mz
Zxy6yucLoBivxf5nAqNB6rbz57hw3VA+dF9vYjjJXofeVxf3aemAc9EMOX4Fs0Y5
RjztbBEiocG9UYk93pxQ25L5zTCEipuV0SWF8H27CD3Lb6obix7g5dkqXNxbLzz6
1qXa3MUZhKAvEtP0ja2yED5/eLKrfGbUPLsrlVKe6J9L6t9WPMROjudEfgFCAJzv
mbSq3dAHvJFpiAqhGdB13I55Xlu1nHhIRs9JhUxK1c2qO20bKU5eXtkHAREhSvKr
5PwVuejYmBUYVytaEsSldBcsA7ftl2aOHgFGV8sCK3QEUDRt5ZIDNno65kv6p484
/Zeo68iIBOaWz2BXFz8iaq52RSKoqiUKblL0JWs57QkE6EUtgVJpt3zV39icTRNK
Rasa2bVZUtXWdeHY0YYvxdZLlckFqI8CAwEAAaOCARUwggERMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFEdYFzD/Q+aVKAyL77fyaAwOGTiWMIHRBgNVHSMEgckw
gcaAFEdYFzD/Q+aVKAyL77fyaAwOGTiWoYGjpIGgMIGdMQswCQYDVQQGEwJDSDEP
MA0GA1UECAwGWnVyaWNoMRIwEAYDVQQHDAlEaWV0bGlrb24xETAPBgNVBAoMCEZv
cnRpbmV0MRwwGgYDVQQLDBNTeXN0ZW1zIEVuZ2luZWVyaW5nMRowGAYDVQQDDBFy
b290Y2EwMS5mdG50LmxhYjEcMBoGCSqGSIb3DQEJARYNaW5mb0BmdG50LmxhYoII
fj6xWAbwx+gwCwYDVR0PBAQDAgGGMA0GCSqGSIb3DQEBCwUAA4ICAQCL3gZxUnkS
pbgmvNjcS1llgVZSzvVvLzczOxzXosIN5+s04hfran1KCoMDdgDfSHle/Z4uSHkm
LESW2gjvqYcPgUgFFDxC4xlgXNa0P8X8ZsB5d1dTIRJvnZtyNVoDitUAPp1zwV5U
KHwlRt/x4oEra7m60wTUKhpIlFWfwgnR6fVUb24UgF7C21n6FnEHlOOII3B5NzlN
ptOmp2fkicfmLLnhrBwombUT9QO+LszNSFtXhScqdYjnngAd9txARStdgfsp4OXi
KgpWnrOS/wnSslDEmjMpp1ATtOpCYV9z4wBadK8XDgDXyLu8RND9QsJd3O2B7GFF
dn3YAmexPGPMhuKChteUMDUQbWIy7vaSu4XWHD2Om/YZur2raEwkrXInLPY3oSF0
bKIwVMQg5jeRHEsu6Bf+ZSuYtRgOMGLnjALD3SRn76ZeVJMa3kCI96GnZHEHsjcR
xxx7XIgl8QKGa+4QSGy7ynWnnguDndt3APAgD59C02w3PyJKZr05Wp+TocWgG5Nt
vg27nZOS2IxwCbHkIGHegHmtw2Jrwibru8WQsfoPCx3Lq/uVjmacLC7QTYwEGKNu
UtCYH9zjjcFrUGmTa19+a2LHIRxzFDPCoFs7MCzoAl/2BhvvjGZsouC4zAB/5Skj
V3yEQ4+SGCCCBYEaHe4mq3lxN2MjIGVLgQ==
-----END CERTIFICATE-----
EOF
)

# Check for sshpass availability
if command -v sshpass &>/dev/null; then
  USE_SSHPASS=1
else
  USE_SSHPASS=0
  echo "Warning: sshpass not found. You will be prompted for your password each time this script runs an scp/ssh command."
fi

# Usage: add_repo.sh <IP_or_FQDN>
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <IP_or_FQDN>"
  exit 1
fi

TARGET="$1"

# Prompt for username (and password if sshpass is available)
read -p "Enter username [admin]: " USERNAME
USERNAME=${USERNAME:-admin}

echo gaga1
if [ $USE_SSHPASS -eq 1 ]; then
  read -sp "Enter password: " PASSWORD
  echo
else
  echo "Note: You will be prompted for your password for each SCP/SSH command."
fi

echo gag2
# Write the certificate content to a temporary file
TMP_CERT=$(mktemp /tmp/"$CERT_FILE".XXXXXX)
echo "$CERT_CONTENT" > "$TMP_CERT"

echo gag3
# Upload the certificate file to the remote machine's home directory using the variable name
# Do not store the ssh key
#echo "Uploading certificate to $TARGET..."
if [ $USE_SSHPASS -eq 1 ]; then
  sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TMP_CERT" "$USERNAME@$TARGET:~/$CERT_FILE"
  scp_status=$?
else
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TMP_CERT" "$USERNAME@$TARGET:~/$CERT_FILE"
  scp_status=$?
fi
echo gag4

if [ $scp_status -ne 0 ]; then
  echo "Error: Certificate upload failed."
  rm -f "$TMP_CERT"
  exit 1
fi
rm -f "$TMP_CERT"
echo gag5

# SSH into the machine to import the certificate and list CA certificates.
# Using the variable CERT_FILE for the file name.
#echo "Importing certificate on remote machine..."
if [ $USE_SSHPASS -eq 1 ]; then
  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$USERNAME@$TARGET" \
    "system certificate local ca import '$CERT_FILE'"
else
echo gag51
echo "$USERNAME@$TARGET"
echo "system certificate local ca import '$CERT_FILE'"
  #ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$USERNAME@$TARGET" \
  #  "system certificate local ca import '$CERT_FILE'"
fi
echo gag6

# List the CA certificates on the remote machine
#echo "Listing CA certificates on remote machine..."
if [ $USE_SSHPASS -eq 1 ]; then
  REMOTE_OUTPUT=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$USERNAME@$TARGET" \
    "system certificate local ca list")
echo gag61
else
echo gag62
  REMOTE_OUTPUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$USERNAME@$TARGET" \
    "system certificate local ca list")
fi
echo gag7
echo "$REMOTE_OUTPUT"

# Extract the CA ID for the certificate with the given CA_CN.
# Expected output example:
# 1 CACert_1 (C = AT, ST = Vienna, L = Vienna, O = Example, OU = Engineering, CN = rootca.example.com)
CA_ID=$(echo "$REMOTE_OUTPUT" | grep -i "CN *= *${CA_CN}" | awk '{print $1}')
echo gag8

if [ -z "$CA_ID" ]; then
  echo "Error: Could not find a CA certificate with CN=${CA_CN}."
  exit 1
fi

echo gag9
echo "Found CA_ID: $CA_ID"

# Build the JSON string by inserting the variable values and the CA_ID.
JSON_STRING=$(cat <<EOF
{"name": "$REPO_NAME", "source": "$REPO_URI", "date": null, "active": true, "chksum": true, "signed": false, "split": false, "description": "$REPO_DESC", "sync": null, "cli": true, "reg": false, "hide": false, "client_pem": "", "client_key": "", "private_ca": $CA_ID}
EOF
)
echo gag10

echo "Final JSON:"
echo "$JSON_STRING"

# Execute the final remote command to create the repository,
# passing the JSON string as parameter in single quotes.
echo "Creating remote repository on $TARGET..."
if [ $USE_SSHPASS -eq 1 ]; then
  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$USERNAME@$TARGET" \
    "system repository remote create '$JSON_STRING'"
else
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$USERNAME@$TARGET" \
    "system repository remote create '$JSON_STRING'"
fi

echo "Repository creation command executed successfully."
