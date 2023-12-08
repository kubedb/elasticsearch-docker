FROM golang:1.21 AS yq

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates

## build yq binary from ac-3.3.4 branch which has updated go dependencies
RUN set -x \
  && git clone https://github.com/gomodules/yq.git \
  && cd yq \
  && git checkout ac-3.3.4 \
  && CGO_ENABLED=0 go build -v -o /yq yq.go

FROM {ELASTICSEARCH_IMAGE} as elasticsearch

FROM alpine:3.18.5

RUN apk add --no-cache bash
COPY scripts/config-merger.sh /usr/local/bin/config-merger.sh
COPY --from=yq /yq /usr/bin/yq
COPY --from=elasticsearch /usr/share/opensearch/config /elasticsearch/default-config
COPY --from=elasticsearch /usr/share/opensearch/plugins/opensearch-security/securityconfig /elasticsearch/default-securityconfig

RUN chmod -c 755 /usr/local/bin/config-merger.sh

ENTRYPOINT ["/bin/bash","/usr/local/bin/config-merger.sh"]