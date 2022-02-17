#!/bin/bash
set -x
sync

SERVER='http://localhost:9200'

if [ "$ENABLE_SSL" == true ]; then
    SERVER='https://localhost:9200'
fi

until curl -s "$SERVER" --insecure; do
    sleep 0.1
done

if [ "$DISABLE_SECURITY" != true ]; then
    bash /usr/share/elasticsearch/plugins/search-guard-5/tools/sgadmin.sh \
        -cd /usr/share/elasticsearch/plugins/search-guard-5/sgconfig/ \
        -icl -nhnv \
        -cacert /usr/share/elasticsearch/config/certs/admin/ca.crt \
        -cert /usr/share/elasticsearch/config/certs/admin/tls.crt \
        -key /usr/share/elasticsearch/config/certs/admin/tls.key
fi
