#!/bin/bash
#===============================================================================
# SCRIPT NAME:    gen_aspex_ca.sh
# DESCRIPTION:    Generate private key and certificate for Aspex Private CA
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-14
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
#===============================================================================
# SET STRICT MODE: Makes script safer by handling errors and undefined variables
set -euo pipefail
IFS=$'\n\t'

# Resolve the script's directory, handling symlinks if possible
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P 2>/dev/null || pwd -P)
FABRIC_HOME=$(dirname "$SCRIPT_DIR")

# Certificate name and path
CERTDIR=$FABRIC_HOME/cert
CERTNAM=aspex
[ ! -d $CERTDIR/$CERTNAM ] && mkdir -p $CERTDIR/$CERTNAM

if [ -f $CERTDIR/$CERTNAM/ca.key -a $CERTDIR/$CERTNAM/ca.crt ]; then 
  echo "ERROR: CA Certificate ($CERTDIR/$CERTNAM/ca.crt) and Private Key ($CERTDIR/$CERTNAM/ca.key) already created."
  echo "       aborting as overwriting these files makes the existing server certificates invalid"
  echo ""
  exit 0
fi

openssl genrsa -out $CERTDIR/$CERTNAM/ca.key 4096

cat > $CERTDIR/$CERTNAM/ca.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir = .
database = \$dir/index.txt
serial = \$dir/serial
new_certs_dir = \$dir/certs
certificate = \$dir/ca.crt
private_key = \$dir/ca.key
default_md = sha256
policy = policy_any
default_days = 3650

[ policy_any ]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied

[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
CN = Aspex Private CA

[ v3_ca ]
basicConstraints = critical,CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF

touch index.txt
echo 1000 > serial
openssl req -x509 -new -nodes -key $CERTDIR/$CERTNAM/ca.key -sha256 -days 3650 -out $CERTDIR/$CERTNAM/ca.crt -config $CERTDIR/$CERTNAM/ca.cnf

