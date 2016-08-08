#!/usr/bin/env bats

wait_for_rabbitmq() {
  for _ in $(seq 1 25); do
    if rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf list queues >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "RabbitMQ did not come online!"
  return 1
}

setup() {
  unset SCRIPT_PID

  echo "test setup..."
  export OLD_RABBITMQ_MNESIA_BASE="$RABBITMQ_MNESIA_BASE"
  export RABBITMQ_MNESIA_BASE=/tmp/datadir
  mkdir "$RABBITMQ_MNESIA_BASE"

  USERNAME=user PASSPHRASE=pass DATABASE=db /usr/bin/wrapper --initialize

  /usr/bin/wrapper &
  export SCRIPT_PID=$!

  wait_for_rabbitmq
}

teardown() {
  # If RabbitMQ was started, shut it down
  if [[ -n "$SCRIPT_PID" ]]; then
    pkill -TERM -P "$SCRIPT_PID"
    wait "$SCRIPT_PID"
  fi

  rm -rf /var/db/testca
  rm -rf /var/db/server
  rm -rf "$RABBITMQ_MNESIA_BASE"
  export RABBITMQ_MNESIA_BASE="$OLD_RABBITMQ_MNESIA_BASE"
  unset OLD_RABBITMQ_MNESIA_BASE

  # Force shutdown the Erlang application server, regardless of whether it was
  # started.
  epmd -kill || true
}

@test "It should bring up a working RabbitMQ instance" {
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf list queues vhost name
    [ "$status" -eq "0" ]
}

@test "It should be able to declare an exchange" {
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare exchange name=my-new-exchange type=fanout
    [ "$status" -eq "0" ]
}

@test "It should be able to declare a queue" {
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare queue name=my-new-queue durable=false
    [ "$status" -eq "0" ]
}

@test "It should be able to publish and retrieve a message" {
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare exchange name=my-new-exchange type=fanout
    [ "$status" -eq "0" ]
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare queue name=my-new-queue durable=false
    [ "$status" -eq "0" ]
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf publish exchange=my-new-exchange routing_key=my-new-queue payload="hello, world"
    [ "$status" -eq "0" ]
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf get queue=my-new-queue requeue=false
    [ "$status" -eq "0" ]
}
