FROM mikefarah/yq:4.40.4 as yq

FROM {ELASTICSEARCH_IMAGE} as elasticsearch

FROM alpine:3.18.5

RUN apk add --no-cache bash
COPY scripts/config-merger.sh /usr/local/bin/config-merger.sh
COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=elasticsearch /usr/share/elasticsearch/config /elasticsearch/default-config
# COPY --from=elasticsearch /usr/share/elasticsearch/plugins/search-guard-7/sgconfig /elasticsearch/default-securityconfig

RUN chmod -c 755 /usr/local/bin/config-merger.sh

ENTRYPOINT ["/bin/bash","/usr/local/bin/config-merger.sh"]
