#!/bin/bash
set -o errexit

# TODO: Remove
set -o xtrace

wait_for_rabbitmq() {
  for _ in $(seq 1 25); do
    if rabbitmqctl -q status 2>/dev/null | grep -q 'rabbit'; then
      return 0
    fi

    echo "Waiting for RabbitMQ to come up..."
    sleep 1
  done

  echo "RabbitMQ admin did not come online!"
  return 1
}

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
      -subj "/CN=$(hostname)/O=server/" -nodes -batch
    cd ../testca
    openssl ca -config openssl.cnf -in ../server/req.pem -out \
      ../server/cert.pem -notext -batch -days 10000 -extensions server_ca_extensions
}

if [[ "$1" == "--initialize" ]]; then
    generate_self_signed_certs

    rabbitmq-server &
    rmq_pid="$!"

    # NOTE: We'd love to use `rabbitmqctl wait` here, but it does not actually
    # work.
    wait_for_rabbitmq

    rabbitmqctl add_user "$USERNAME" "$PASSPHRASE"

    # The vhost is equivalent to the "db" in our case
    rabbitmqctl add_vhost "$DATABASE"

    rabbitmqctl set_permissions -p "$DATABASE" "$USERNAME" ".*" ".*" ".*"
    rabbitmqctl set_user_tags "$USERNAME" administrator

    rabbitmqctl delete_user guest

    echo "Waiting for RabbitMQ to exit..."
    pkill -TERM -P "$rmq_pid"
    wait "$rmq_pid" || true
elif [[ "$1" == "--client" ]]; then
    echo "This image does not support the --client option. Use rabbitmqadmin instead." && exit 1
else
  echo "Launching RabbitMQ..."
  exec rabbitmq-server
fi
