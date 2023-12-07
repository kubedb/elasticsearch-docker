FROM golang:1.21 AS yq

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates

## build yq binary from ac-3.3.4 branch which has updated go dependencies
RUN set -x \
  && git clone https://github.com/gomodules/yq.git \
  && cd yq \
  && git checkout ac-3.3.4  \
  && CGO_ENABLED=0 go build -v -o /yq yq.go

FROM {ELASTICSEARCH_DASHBOARD_IMAGE} as elasticsearch_dashboard

FROM alpine:3.18.5

RUN apk add --no-cache bash
COPY scripts/dashboard-config-merger.sh /usr/local/bin/dashboard-config-merger.sh
COPY --from=yq /yq /usr/bin/yq
COPY --from=elasticsearch_dashboard /usr/share/kibana/config /kibana/default-config

RUN chmod -c 755 /usr/local/bin/dashboard-config-merger.sh

# Change the user to non root after the script run
# as non root user don't have file permissions to merge configs
RUN adduser -D kibana -u 1000
USER 1000

ENTRYPOINT ["/bin/bash","/usr/local/bin/dashboard-config-merger.sh"]
