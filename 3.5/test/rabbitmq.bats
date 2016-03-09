#!/usr/bin/env bats

initialize_rabbitmq() {
  echo "test setup..."
  export OLD_RABBITMQ_MNESIA_BASE="$RABBITMQ_MNESIA_BASE"
  export RABBITMQ_MNESIA_BASE=/tmp/datadir
  rm -rf "$RABBITMQ_MNESIA_BASE" && mkdir "$RABBITMQ_MNESIA_BASE"

  USERNAME=user PASSPHRASE=pass DATABASE=db /usr/bin/wrapper --initialize

  sleep 25
}

run_rabbitmq() {
  rabbitmq-server &
  export SCRIPT_PID=$!
  sleep 25
}

teardown() {
  rabbitmqctl stop_app
  rabbitmqctl reset

  pkill -P $SCRIPT_PID

  wait $SCRIPT_PID

  rm -rf /var/db/testca
  rm -rf /var/db/server
  export RABBITMQ_MNESIA_BASE="$OLD_RABBITMQ_MNESIA_BASE"
  unset OLD_RABBITMQ_MNESIA_BASE
}

@test "It should bring up a working RabbitMQ instance" {
    initialize_rabbitmq
    run_rabbitmq
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf list queues vhost name
    [ "$status" -eq "0" ]
}

@test "It should be able to declare an exchange" {
    initialize_rabbitmq
    run_rabbitmq
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare exchange name=my-new-exchange type=fanout 
    [ "$status" -eq "0" ]
}

@test "It should be able to declare a queue" {
    initialize_rabbitmq
    run_rabbitmq
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare queue name=my-new-queue durable=false 
    [ "$status" -eq "0" ]
}

@test "It should be able to publish and retrieve a message" {
    initialize_rabbitmq
    run_rabbitmq
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare exchange name=my-new-exchange type=fanout 
    [ "$status" -eq "0" ]
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf declare queue name=my-new-queue durable=false
    [ "$status" -eq "0" ]
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf publish exchange=my-new-exchange routing_key=my-new-queue payload="hello, world"
    [ "$status" -eq "0" ]
    run rabbitmqadmin -c /usr/local/bin/rabbitmqadmin.conf get queue=my-new-queue requeue=false
    [ "$status" -eq "0" ]
}

@test "It should auto-generate certs when none are provided" {
    name="$(hostname)"
    initialize_rabbitmq | grep "Generating certificate with name $name"
    run_rabbitmq
    curl -kv https://localhost:5671 2>&1 | grep $name
}

@test "It should prioritize ssl cert / key files from the environment" {
    /usr/bin/initialize-certs bats-test | grep "Generating certificate with name bats-test"
    export SSL_CERTIFICATE="$(cat "/var/db/server/cert.pem")"
    export SSL_KEY="$(cat "/var/db/server/key.pem")"
    rm -rf /var/db/testca
    rm -rf /var/db/server
    initialize_rabbitmq | grep "Taking certificate from environment"
    run_rabbitmq
    curl -kv https://localhost:5671 2>&1 | grep bats-test
}

@test "It should reuse existing ssl cert / key files" {
    /usr/bin/initialize-certs bats-test | grep "Generating certificate with name bats-test"
    initialize_rabbitmq | grep "Certs present on filesystem - using them"
    run_rabbitmq
    curl -kv https://localhost:5671 2>&1 | grep bats-test
}
