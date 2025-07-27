#!/bin/bash
#===============================================================================
# SCRIPT NAME:    gen_fortidemo_certificates.sh
# DESCRIPTION:    Generate Service Certificates for the fortidemo.net domain
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
[ $(basename $SCRIPT_DIR) == "fabric-studio" ] && FABRIC_HOME=$SCRIPT_DIR || FABRIC_HOME=$(dirname $SCRIPT_DIR)

# Certificate name and path
CERTDIR=$FABRIC_HOME/cert/fortidemo
CERTTMP=/tmp
[ ! -d $CERTDIR ] && mkdir -p $CERTDIR

if [ ! -f $CERTDIR/ca.key -a $CERTDIR/ca.crt ]; then
  echo "ERROR: CA Certificate ($CERTDIR/ca.crt) and Private Key ($CERTDIR/ca.key) are not created yet."
  echo "       Please run gen_fortidemo_ca.sh first"
  echo ""
  exit 0
fi

################################################################################
################################## CA SIGNING ##################################
################################################################################

cat > $CERTDIR/ca_signing.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $CERTDIR
certs             = $CERTDIR
new_certs_dir     = $CERTDIR
database          = $CERTDIR/index.txt
serial            = $CERTDIR/serial
private_key       = $CERTDIR/ca.key
certificate       = $CERTDIR/ca.crt
default_md        = sha256
policy            = policy_any
email_in_dn       = no
copy_extensions   = copy

[ policy_any ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
EOF

touch $CERTDIR/index.txt
echo 1000 > $CERTDIR/serial
echo "Generate CA Signing Config"
echo "- $CERTDIR/ca_signing.cnf"

################################################################################
###################### CREATE *.apps-int.fortidemo.net #########################
################################################################################
CERTNAM=k3s-apps-internal

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich
L  = Zurich
O  = Fabric-Studio
OU = IT
CN = *.apps-int.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.apps-int.fortidemo.net
DNS.2 = apps-int.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (*.apps-int.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"

################################################################################
###################### CREATE echoserver.apps-adc.fortidemo.net #########################
################################################################################
CERTNAM=k3s-apps-adc-echoserver

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich
L  = Zurich
O  = Fabric-Studio
OU = IT
CN = echoserver.apps-adc.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = echoserver.apps-adc.fortidemo.net
DNS.2 = echoserver.apps-adc.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (echosrver.apps-adc.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"

################################################################################
###################### CREATE toolbox.apps-adc.fortidemo.net #########################
################################################################################
CERTNAM=k3s-apps-adc-toolbox

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich
L  = Zurich
O  = Fabric-Studio
OU = IT
CN = toolbox.apps-adc.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = toolbox.apps-adc.fortidemo.net
DNS.2 = toolbox.apps-adc.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (toolbox.apps-adc.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"

################################################################################
###################### CREATE fadcdemo.apps-adc.fortidemo.net #########################
################################################################################
CERTNAM=k3s-apps-adc-fadcdemo

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich
L  = Zurich
O  = Fabric-Studio
OU = IT
CN = fadcdemo.apps-adc.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = fadcdemo.apps-adc.fortidemo.net
DNS.2 = fadcdemo.apps-adc.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (fadcdemo.apps-adc.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"

################################################################################
###################### CREATE edb.apps-adc.fortidemo.net #########################
################################################################################
CERTNAM=k3s-apps-adc-edb

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich
L  = Zurich
O  = Fabric-Studio
OU = IT
CN = edb.apps-adc.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = edb.apps-adc.fortidemo.net
DNS.2 = edb.apps-adc.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (edb.apps-adc.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"


################################################################################
########3############### CREATE *.apps.fortidemo.net #########3#################
################################################################################
CERTNAM=k3s-apps-external

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich
L  = Zurich
O  = Fabric-Studio
OU = IT
CN = *.apps.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.apps.fortidemo.net
DNS.2 = apps.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (*.apps.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"

################################################################################
######################## CREATE fortigate.fortidemo.net ########################
################################################################################
CERTNAM=fortigate

# Create a Private Key for the Server
openssl genpkey -algorithm RSA -out $CERTDIR/${CERTNAM}.key -pkeyopt rsa_keygen_bits:2048 > /dev/null 2>&1

# Create a configuration file (server_cert.cnf) to include the Subject Alternative Name (SAN):
cat > $CERTDIR/${CERTNAM}.cnf <<EOF
[ req ]
default_bits       = 2048
prompt            = no
default_md        = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
C  = CH
ST = Zurich       
L  = Zurich       
O  = Fabric-Studio
OU = IT
CN = fortigate.fortidemo.net

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]           
DNS.1 = fortigate.fortidemo.net
DNS.2 = proxy.fortidemo.net
DNS.2 = portal.fortidemo.net
EOF

# generate the CSR
openssl req -new -key $CERTDIR/${CERTNAM}.key -out $CERTDIR/${CERTNAM}.csr -config $CERTDIR/${CERTNAM}.cnf

# Sign the certificate:
openssl x509 -req -in $CERTDIR/${CERTNAM}.csr -CA $CERTDIR/ca.crt -CAkey $CERTDIR/ca.key \
    -CAcreateserial -out $CERTDIR/${CERTNAM}.crt -days 3650 -sha256 -extfile $CERTDIR/${CERTNAM}.cnf -extensions v3_req > /dev/null 2>&1

echo
echo "Certificates Generated for Domain (fortigate.fortidemo.net):"
echo " - $CERTDIR/${CERTNAM}.crt"
echo " - $CERTDIR/${CERTNAM}.key"



exit

