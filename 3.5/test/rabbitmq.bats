#!/usr/bin/env bats

setup() {
  echo "test setup..."
  export OLD_RABBITMQ_MNESIA_BASE="$RABBITMQ_MNESIA_BASE"
  export RABBITMQ_MNESIA_BASE=/tmp/datadir
  mkdir "$RABBITMQ_MNESIA_BASE"
  cp -r /ssl /ssl-old

  USERNAME=user PASSPHRASE=pass DB=db /usr/bin/wrapper --initialize  > /dev/null 2>&1

  sleep 25

  rabbitmq-server > /dev/null 2>&1 &

  export SCRIPT_PID=$!

  sleep 25
}

teardown() {
  rabbitmqctl stop_app  > /dev/null 2>&1
  rabbitmqctl reset  > /dev/null 2>&1

  pkill -P $SCRIPT_PID

  wait $SCRIPT_PID

  rm -rf "$RABBITMQ_MNESIA_BASE"
  rm -rf /ssl
  mv /ssl-old /ssl
  export RABBITMQ_MNESIA_BASE="$OLD_RABBITMQ_MNESIA_BASE"
  unset OLD_RABBITMQ_MNESIA_BASE
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
