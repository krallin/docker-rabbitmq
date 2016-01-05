#!/bin/bash

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p)' EXIT

# Die on error
set -e

function generate_self_signed_certs {
    echo "Generating certificates"
    cd /ssl/testca
    mkdir certs private
    chmod 700 private
    echo 01 > serial
    touch index.txt

    openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 10000 \
        -out cacert.pem -outform PEM -subj /CN=MyTestCA/ -nodes
    openssl x509 -in cacert.pem -out cacert.cer -outform DER

    cd ..
    mkdir server
    cd server
    openssl genrsa -out key.pem 2048
    openssl req -new -key key.pem -out req.pem -days 10000 -outform PEM \
	        -subj /CN=$(hostname)/O=server/ -nodes -batch
    cd ../testca
    openssl ca -config openssl.cnf -in ../server/req.pem -out \
	        ../server/cert.pem -notext -batch -days 10000 -extensions server_ca_extensions
    mv cacert.pem /ssl
    mv ../server/cert.pem /ssl
    mv ../server/key.pem /ssl
}

if [[ "$1" == "--initialize" ]]; then
    generate_self_signed_certs

    ${RABBITMQ_HOME}/sbin/rabbitmq-server &

    sleep 25

    ${RABBITMQ_HOME}/sbin/rabbitmqctl add_user aptible $PASSPHRASE
    ${RABBITMQ_HOME}/sbin/rabbitmqctl add_vhost db

    ${RABBITMQ_HOME}/sbin/rabbitmqctl set_permissions -p db aptible ".*" ".*" ".*"
    ${RABBITMQ_HOME}/sbin/rabbitmqctl set_user_tags aptible administrator

    ${RABBITMQ_HOME}/sbin/rabbitmqctl delete_user guest
    ${RABBITMQ_HOME}/sbin/rabbitmqctl delete_vhost /
else
    echo "Launching RabbitMQ..."
    ${RABBITMQ_HOME}/sbin/rabbitmq-server &

    # Capture the PID
    rmq_pid=$!

    # Tail the logs, but continue on to the wait command
    echo -e "\n\nTailing log output:"

    # If RMQ dies, this script dies
    wait $rmq_pid
fi

