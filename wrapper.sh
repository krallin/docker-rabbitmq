#!/bin/bash

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p)' EXIT

# Die on error
set -e

# If long & short hostnames are not the same, use long hostnames
if ! [[ "$(hostname)" == "$(hostname -s)" ]]; then
    export RABBITMQ_USE_LONGNAME=true
fi

#sed -i "s,CERTFILE,/var/db/server.crt,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
#sed -i "s,KEYFILE,/var/db/server.key,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
#sed -i "s,CAFILE,$SSL_CA_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config

if [[ "$1" == "--initialize" ]]; then
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

