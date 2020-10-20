#!/bin/bash
#
## Openssl CA setup from https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
#
#set -x

INSTALL_HOME=/root/myCA
mkdir -p ${INSTALL_HOME}
## Uncomment the following lines for script debugging.
#LOG_FILE=${INSTALL_HOME}/`basename "$0" | awk -F\. '{print $1}'`.log
#exec &> ${LOG_FILE}

if [[ ! ${USER} =~ .*root* ]]
then
   echo "Script must be run as root: exiting"
   exit 1
fi

cd ${INSTALL_HOME}
mkdir certs crl newcerts private intermediate
chmod 700 private
touch index.txt
echo 1000 > serial

# Create the Root CA configuration file.
echo ""
echo "Creating openssl.conf file in ${INSTALL_HOME}"

cat << EOF > ${INSTALL_HOME}/openssl.cnf
# OpenSSL root CA configuration file.
#
[ ca ]
# see man page, ('man ca')
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = /root/myCA
certs             = /root/myCA/certs
crl_dir           = /root/myCA/crl
new_certs_dir     = /root/myCA/newcerts
database          = /root/myCA/index.txt
serial            = /root/myCA/serial
RANDFILE          = /root/myCA/private/.rand

# The root key and root certificate.
private_key       = /root/myCA/private/ca.key.pem
certificate       = /root/myCA/certs/ca.cert.pem

# For certificate revocation lists.
crlnumber         = /root/myCA/crlnumber
crl               = /root/myCA/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of 'man ca'.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the 'ca' man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the 'req' tool ('man req').
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = MA
localityName_default            = Boston
0.organizationName_default      = Cloudera
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[ crl_ext ]
# Extension for CRLs ('man x509v3_config').
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates ('man ocsp').
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF

##################################################
# Create the file structure for the Intermediate CA
echo "Create file structure for the Intermediate CA"
cd ${INSTALL_HOME}/intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial 

echo ""
echo "Creating openssl.conf for the Intermediate CA"
# Create the Intermediate CA configuration file.
cat << EOF > ${INSTALL_HOME}/intermediate/openssl.cnf
# OpenSSL intermediate CA configuration file.
[ ca ]
# see man page (man ca).
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = /root/myCA/intermediate
certs             = /root/myCA/intermediate/dir/certs
crl_dir           = /root/myCA/intermediate/crl
new_certs_dir     = /root/myCA/intermediate/newcerts
database          = /root/myCA/intermediate/index.txt
serial            = /root/myCA/intermediate/serial
RANDFILE          = /root/myCA/intermediate/private/.rand

# The root key and root certificate.
private_key       = /root/myCA/intermediate/private/intermediate.key.pem
certificate       = /root/myCA/intermediate/certs/intermediate.cert.pem

# For certificate revocation lists.
crlnumber         = /root/myCA/intermediate/crlnumber
crl               = /root/myCA/intermediate/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of 'man ca'.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the 'ca' man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the 'req' tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = MA
localityName_default            = Boston
0.organizationName_default      = Cloudera
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs ('man x509v3_config').
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates ('man ocsp').
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF

#######
# Create the Root Certificate
cd ${INSTALL_HOME}

echo ""
echo "Creating Root Private Key"
openssl genrsa -aes256 -out private/ca.key.pem 4096 -passin pass:cloudera

echo ""
echo "Creating Root Cert File"
openssl req -config openssl.cnf \
      -key private/ca.key.pem -passin pass:cloudera \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem \
      -subj "/C=US/ST=MA/L=Boston/O=Security/OU=Support/CN=myRootCA"

# Add a crlnumber file to the Intermediate CA direcotry. The 'crlnumber' is used to keep track of CRLs.
echo 1000 > ${INSTALL_HOME}/intermediate/crlnumber

# Create the Intermediate key.
echo ""
echo "Creating the Intermediate private key"
cd ${INSTALL_HOME}
openssl genrsa -aes256 -passout pass:cloudera \
      -out intermediate/private/intermediate.key.pem 4096

chmod 400 intermediate/private/intermediate.key.pem

# Create the Intermediate CSR.
echo ""
echo "Creating the Intermediate CSR now"
cd ${INSTALL_HOME}
openssl req -config intermediate/openssl.cnf -new -sha256 \
      -key intermediate/private/intermediate.key.pem -passin pass:cloudera\
      -out intermediate/csr/intermediate.csr.pem \
      -subj "/C=US/ST=MA/L=Boston/O=Security/OU=Support/CN=myInterCA"

# Create the Intermediate Certificate.
# we need to sign it as an intermediate certiicate, using '-extentions v3_intermediate_ca' to sign
echo ""
echo "Signing the Intermediate Certificate"
cd ${INSTALL_HOME}
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 -passin pass:cloudera\
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

chmod 444 intermediate/certs/intermediate.cert.pem


echo " 	DONE "




