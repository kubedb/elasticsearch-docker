FROM debian:bullseye as builder

# ref: https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS
ARG TARGETARCH

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl unzip

RUN set -x \
  && curl -fsSL -o yq https://github.com/mikefarah/yq/releases/download/3.3.0/yq_${TARGETOS}_${TARGETARCH} \
  && chmod 755 yq

FROM {ELASTICSEARCH_IMAGE} as elasticsearch

RUN IFS=',' read -ra PLUGINS <<< "{ELASTICSEARCH_PLUGINS}"; for PLUGIN in "${PLUGINS[@]}"; do /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch $PLUGIN ;done;
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin list

COPY scripts/config-merger.sh /usr/local/bin/config-merger.sh
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --from=builder /yq /usr/bin/yq
RUN mkdir -p /elasticsearch/default-config
RUN cp -r /usr/share/elasticsearch/config/* /elasticsearch/default-config/
RUN chown 1000:0 -R /elasticsearch/default-config

RUN chmod -c 755 /usr/local/bin/config-merger.sh
RUN chmod -c 755 /usr/local/bin/docker-entrypoint.sh