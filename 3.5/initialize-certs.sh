#!/bin/bash

ssl_directory="/var/db/server"
ssl_cert_file="${ssl_directory}/cert.pem"
ssl_key_file="${ssl_directory}/key.pem"

if [ -f "$ssl_cert_file" ] && [ -f "$ssl_key_file" ]; then
    echo "Certs present on filesystem - using them"
elif [ -n "$SSL_CERTIFICATE" ] && [ -n "$SSL_KEY" ]; then
    echo "Taking certificate from environment"
    echo -e "$SSL_KEY" > key.pem
    echo -e "$SSL_CERTIFICATE" > cert.pem
    echo -e "$SSL_CERTIFICATE" > cacert.pem

    mkdir /var/db/server
    mkdir /var/db/testca
    mv key.pem $ssl_directory
    mv cert.pem $ssl_directory
    mv cacert.pem /var/db/testca
else
    [[ -n $1 ]] && name="$1" || name=$(hostname)

    echo "Generating certificate with name $name"

    cp -r /ssl/testca /var/db/testca
    cd /var/db/testca

    mkdir certs private
    chmod 700 private
    echo 01 > serial
    touch index.txt

    openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 10000 \
        -out cacert.pem -outform PEM -subj /CN=MyTestCA -nodes
    openssl x509 -in cacert.pem -out cacert.cer -outform DER

    cd ..
    mkdir server
    cd server
    openssl genrsa -out key.pem 2048
    openssl req -new -key key.pem -out req.pem -days 10000 -outform PEM \
            -subj /CN=${name}/O=server/ -nodes -batch
    cd ../testca
    openssl ca -config openssl.cnf -in ../server/req.pem -out \
            ../server/cert.pem -notext -batch -days 10000 -extensions server_ca_extensions
fi