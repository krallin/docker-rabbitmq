FROM        quay.io/aptible/alpine 

ENV         RABBITMQ_HOME=/srv/rabbitmq_server-3.5.7 \
            PLUGINS_DIR=/srv/rabbitmq_server-3.5.7/plugins \
            ENABLED_PLUGINS_FILE=/srv/rabbitmq_server-3.5.7/etc/rabbitmq/enabled_plugins \
            RABBITMQ_MNESIA_BASE=/var/db/rabbitmq \
            RABBITMQ_MNESIA_DIR=/var/db/rabbitmq/db \
            DATA_DIRECTORY=/var/db \
            RABBITMQ_LOGS=- \ 
            RABBITMQ_SASL_LOGS=-

COPY        cacert.pem  /ssl/cacert.pem
COPY        key.pem     /ssl/key.pem
COPY        cert.pem    /ssl/cert.pem
COPY        rabbitmq.config /srv/rabbitmq_server-3.5.7/etc/rabbitmq/
COPY        wrapper.sh /usr/bin/wrapper
ADD         https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_5_7/rabbitmq-server-generic-unix-3.5.7.tar.gz /srv/rabbitmq-server-generic-unix-3.5.7.tar.gz
RUN         chmod a+x /usr/bin/wrapper && apk add --update curl tar gzip bash && \
            echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
            echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
            echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
            apk add erlang erlang erlang-mnesia erlang-public-key erlang-crypto erlang-ssl \
                erlang-sasl erlang-asn1 erlang-inets erlang-os-mon erlang-xmerl erlang-eldap \
                --update-cache --allow-untrusted && \
            cd /srv && \
            tar -xzvf rabbitmq-server-generic-unix-3.5.7.tar.gz && \
            rm -f rabbitmq-server-generic-unix-3.5.7.tar.gz && \
            touch /srv/rabbitmq_server-3.5.7/etc/rabbitmq/enabled_plugins && \
            /srv/rabbitmq_server-3.5.7/sbin/rabbitmq-plugins enable --offline rabbitmq_management && \
            apk del --purge tar gzip && \
            mkdir $DATA_DIRECTORY

EXPOSE      15671 5671
VOLUME      ["$DATA_DIRECTORY"]
ENTRYPOINT  ["/usr/bin/wrapper"]

