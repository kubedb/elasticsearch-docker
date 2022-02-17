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

# Install mapper-attachments (https://www.elastic.co/guide/en/elasticsearch/plugins/5.x/mapper-attachments.html)
RUN ./bin/elasticsearch-plugin install ingest-attachment

# Install search-guard
RUN ./bin/elasticsearch-plugin install -b com.floragunn:search-guard-5:5.6.16-19.4

COPY scripts/config-merger.sh /usr/local/bin/config-merger.sh
COPY scripts/run_sgadmin.sh /usr/local/bin/run_sgadmin.sh

COPY --from=builder /yq /usr/bin/yq
RUN mkdir -p /elasticsearch/default-config
RUN cp -r /usr/share/elasticsearch/config/* /elasticsearch/default-config/
RUN chown 1000:0 -R /elasticsearch/default-config

RUN mkdir -p /elasticsearch/default-securityconfig
RUN cp -r /usr/share/elasticsearch/plugins/search-guard-5/sgconfig/* /elasticsearch/default-securityconfig/
RUN chown 1000:0 -R /elasticsearch/default-securityconfig

RUN chmod -c 755 /usr/local/bin/config-merger.sh
RUN chmod -c 755 /usr/local/bin/run_sgadmin.sh

CMD ["/bin/bash","-c", "/usr/local/bin/run_sgadmin.sh & /usr/share/elasticsearch/bin/elasticsearch"]