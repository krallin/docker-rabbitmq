FROM        quay.io/aptible/alpine 

ENV         RABBITMQ_VERSION=3.5.7 \
            RABBITMQ_MNESIA_BASE=/var/db/rabbitmq \
            DATA_DIRECTORY=/var/db \
            RABBITMQ_LOGS=- \ 
            RABBITMQ_SASL_LOGS=-
ENV         RABBITMQ_HOME=/srv/rabbitmq_server-${RABBITMQ_VERSION} \
            PLUGINS_DIR=/srv/rabbitmq_server-${RABBITMQ_VERSION}/plugins \
            ENABLED_PLUGINS_FILE=/srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/enabled_plugins
ENV         PATH=$RABBITMQ_HOME/sbin:$PATH

RUN         mkdir /srv && apk add --update curl tar gzip bash && \
            curl -Lk "https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v${RABBITMQ_VERSION//\./_}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz" > /srv/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
            echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
            echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
            echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
            apk add python erlang erlang erlang-mnesia erlang-public-key erlang-crypto erlang-ssl \
                erlang-sasl erlang-asn1 erlang-inets erlang-os-mon erlang-xmerl erlang-eldap \
                --update-cache --allow-untrusted && \
            cd /srv && \
            tar -xzvf rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
            rm -f rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
            touch /srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/enabled_plugins && \
            /srv/rabbitmq_server-${RABBITMQ_VERSION}/sbin/rabbitmq-plugins enable --offline rabbitmq_management && \
            apk del --purge tar gzip && \
            mkdir $DATA_DIRECTORY

COPY        openssl.cnf /ssl/testca/openssl.cnf
COPY        rabbitmq.config /srv/rabbitmq_server-${RABBITMQ_VERSION}/etc/rabbitmq/
COPY        run-database.sh /usr/bin/wrapper
COPY        rabbitmqadmin /usr/local/bin/rabbitmqadmin
COPY        rabbitmqadmin.conf /usr/local/bin/rabbitmqadmin.conf

ADD         test /tmp/test
RUN         ln -s /var/db/testca/cacert.pem /ssl/cacert.pem && \
            ln -s /var/db/server/cert.pem /ssl/cert.pem && \
            ln -s /var/db/server/key.pem /ssl/key.pem && \
            chmod a+x /usr/bin/wrapper /usr/local/bin/rabbitmqadmin && \
            bats --tap /tmp/test && apk del --purge python
EXPOSE      15671 5671
VOLUME      ["$DATA_DIRECTORY"]
ENTRYPOINT  ["/usr/bin/wrapper"]

