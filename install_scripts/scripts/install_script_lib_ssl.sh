#!/bin/bash
#
# To setup a new SSL architecture
#


# Create working directory
mkdir -p /srv/ssl
cd /srv/ssl

# Create ssl structure
mkdir certs crl newcerts private export

# Initialize values
echo 01 > serial
touch index.txt
cp /usr/lib/ssl/openssl.cnf .





# OpenSSL configuration

## TODO ask for 

dir = /srv/ssl                            # Where everything is kept  [line 42]
 
[ req_distinguished_name ]
countryName_default             = SE                        # [line 128]   
stateOrProvinceName_default     = Västra Götaland           # [line 134]
localityName_default            = Goteborg                  # [line 137]
0.organizationName_default      = Daxiongmao.eu             # [line 140]
emailAddress_default            = guillaume@qin-diaz.com    # [line 154]
