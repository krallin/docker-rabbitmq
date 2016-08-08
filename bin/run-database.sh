#!/bin/bash

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p)' EXIT

# Die on error
set -e

if [[ "$1" == "--initialize" ]]; then
    /usr/bin/initialize-certs

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
    /usr/bin/initialize-certs

    echo "Launching RabbitMQ..."

    rabbitmq-server &

    # Capture the PID
    rmq_pid=$!

    # Tail the logs, but continue on to the wait command
    echo -e "\n\nTailing log output:"

    # If RMQ dies, this script dies
    wait $rmq_pid
fi

