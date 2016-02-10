#!/bin/bash

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p)' EXIT

# Die on error
set -e

function generate_self_signed_certs {
    echo "Generating certificates"

    cp -r /ssl/testca /var/db/testca
    cd /var/db/testca

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
}

if [[ "$1" == "--initialize" ]]; then
    generate_self_signed_certs

    rabbitmq-server &

    sleep 25

    rabbitmqctl add_user $USERNAME $PASSPHRASE

    # The vhost is equivalent to the "db" in our case
    rabbitmqctl add_vhost $DATABASE

    rabbitmqctl set_permissions -p $DATABASE $USERNAME ".*" ".*" ".*"
    rabbitmqctl set_user_tags $USERNAME administrator

    rabbitmqctl delete_user guest

    rabbitmqctl stop_app
elif [[ "$1" == "--client" ]]; then
    echo "This image does not support the --client option. Use rabbitmqadmin instead." && exit 1
else
    echo "Launching RabbitMQ..."

    rabbitmq-server &

    # Capture the PID
    rmq_pid=$!

    # Tail the logs, but continue on to the wait command
    echo -e "\n\nTailing log output:"

    # If RMQ dies, this script dies
    wait $rmq_pid
fi

