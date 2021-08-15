FROM debian:stretch as builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl unzip

RUN set -x                                                                                             \
  && curl -fsSL -o yq https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 \
  && chmod 755 yq

FROM {ELASTICSEARCH_IMAGE} as elasticsearch

FROM alpine:3.13.1

RUN apk add --no-cache bash
COPY config-merger.sh /usr/local/bin/config-merger.sh
COPY --from=builder /yq /usr/bin/yq
COPY --from=elasticsearch /usr/share/elasticsearch/config /elasticsearch/default-config
COPY --from=elasticsearch /usr/share/elasticsearch/plugins/search-guard-7/sgconfig /elasticsearch/default-securityconfig

RUN chmod -c 755 /usr/local/bin/config-merger.sh

ENTRYPOINT ["/bin/bash","/usr/local/bin/config-merger.sh"]
