FROM debian:stretch as builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl unzip

RUN set -x                                                                                             \
  && curl -fsSL -o yq https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 \
  && chmod 755 yq



FROM elasticsearch:7.13.4 as elasticsearch

RUN ls -la /usr/share/elasticsearch/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch repository-s3
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch repository-gcs
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch repository-hdfs
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch repository-azure
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin list

RUN ls -la /usr/share/elasticsearch/config/


# FROM {ELASTICSEARCH_IMAGE} as elasticsearch

# FROM alpine:3.13.1

# RUN apk add --no-cache bash
COPY config-merger.sh /usr/local/bin/config-merger.sh
COPY --from=builder /yq /usr/bin/yq
RUN mkdir -p /elasticsearch/default-config
RUN cp -r /usr/share/elasticsearch/config/* /elasticsearch/default-config/
RUN chown 1000:0 -R /elasticsearch/default-config
RUN ls -la /usr/share/elasticsearch/.config
RUN ls -la /elasticsearch/default-config
# COPY --from=elasticsearch /usr/share/elasticsearch/config /elasticsearch/default-config
# COPY --from=elasticsearch /usr/share/elasticsearch/plugins/opendistro_security/securityconfig /elasticsearch/default-securityconfig

RUN chmod -c 755 /usr/local/bin/config-merger.sh

# https://stackoverflow.com/a/41207569/11032044
ENTRYPOINT ["/usr/bin/env"]

# ENTRYPOINT ["/bin/bash","/usr/local/bin/config-merger.sh"]