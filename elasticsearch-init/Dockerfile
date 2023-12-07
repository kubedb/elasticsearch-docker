FROM golang:1.21 AS builder

ARG TARGETOS
ARG TARGETARCH

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates

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
COPY --from=elasticsearch /usr/share/elasticsearch/config /elasticsearch/default-config
# COPY --from=elasticsearch /usr/share/elasticsearch/plugins/search-guard-7/sgconfig /elasticsearch/default-securityconfig

RUN chmod -c 755 /usr/local/bin/config-merger.sh

ENTRYPOINT ["/bin/bash","/usr/local/bin/config-merger.sh"]
