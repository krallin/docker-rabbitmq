#!/bin/bash
set -o errexit

with_retry () {
  # When RabbitMQ is just booting up, it might be impossible to e.g. create a
  # new user because no worker is available to service our request (the error
  # looks like `noproc,{gen_server2,call ...}`). Even if we wait until RabbitMQ
  # appears to be online (i.e. it shows in rabbitmqctl's status output), we can
  # stil run into an error while adding the user. So, we just retry a lot!
  local n=30
  local d=2

  for _ in $(seq 1 "$n"); do
    if "$@"; then
      return 0
    fi

    echo "Errored (may retry in ${d}): ${*}"
    sleep "$d"
  done

  echo "Failed permanently after ${n} attempts: ${*}"
  return 1
}

if [[ "$1" == "--initialize" ]]; then
    /usr/bin/initialize-certs

    rabbitmq-server &
    rmq_pid="$!"

    with_retry rabbitmqctl add_user "$USERNAME" "$PASSPHRASE"

    # The vhost is equivalent to the "db" in our case
    with_retry rabbitmqctl add_vhost "$DATABASE"

    with_retry rabbitmqctl set_permissions -p "$DATABASE" "$USERNAME" ".*" ".*" ".*"
    with_retry rabbitmqctl set_user_tags "$USERNAME" administrator

    with_retry rabbitmqctl delete_user guest

    echo "Waiting for RabbitMQ to exit..."
    pkill -TERM -P "$rmq_pid"
    wait "$rmq_pid" || true
elif [[ "$1" == "--client" ]]; then
    echo "This image does not support the --client option. Use rabbitmqadmin instead." && exit 1
else
    /usr/bin/initialize-certs
    echo "Launching RabbitMQ..."
    exec rabbitmq-server
fi
