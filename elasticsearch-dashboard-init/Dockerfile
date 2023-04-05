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

FROM {ELASTICSEARCH_DASHBOARD_IMAGE} as elasticsearch_dashboard

FROM alpine:3.13.1
LABEL org.opencontainers.image.source https://github.com/kubedb/elasticsearch-docker

RUN apk add --no-cache bash
COPY scripts/dashboard-config-merger.sh /usr/local/bin/dashboard-config-merger.sh
COPY --from=builder /yq /usr/bin/yq
COPY --from=elasticsearch_dashboard /usr/share/kibana/config /kibana/default-config

RUN chmod -c 755 /usr/local/bin/dashboard-config-merger.sh

# Change the user to non root after the script run
# as non root user don't have file permissions to merge configs
RUN adduser -D kibana -u 1000
USER 1000

ENTRYPOINT ["/bin/bash","/usr/local/bin/dashboard-config-merger.sh"]
