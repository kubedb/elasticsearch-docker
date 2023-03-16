SHELL=/bin/bash -o pipefail

REGISTRY   ?= kubedb
BIN        ?= elasticsearch-dashboard-init
IMAGE      := $(REGISTRY)/$(BIN)
TAG        ?= $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

DOCKER_PLATFORMS := linux/amd64 linux/arm64
PLATFORM         ?= $(firstword $(DOCKER_PLATFORMS))
VERSION          = $(TAG)_$(subst /,_,$(PLATFORM))

DASHBOARD_REGISTRY	?=
DASHBOARD_BIN		?= kibana
DASHBOARD_TAG		?= 8.6.2
DASHBOARD_IMAGE	?= $(shell if [ ! -z $(DASHBOARD_REGISTRY) ]; then echo $(DASHBOARD_REGISTRY)/; fi)$(DASHBOARD_BIN):$(DASHBOARD_TAG)

BUILD_DIRS := bin

$(BUILD_DIRS):
	@mkdir -p $@

container-%:
	@$(MAKE) container \
	    --no-print-directory \
	    PLATFORM=$(subst _,/,$*)

push-%:
	@$(MAKE) push \
	    --no-print-directory \
	    PLATFORM=$(subst _,/,$*)

all-container: $(addprefix container-, $(subst /,_,$(DOCKER_PLATFORMS)))

all-push: $(addprefix push-, $(subst /,_,$(DOCKER_PLATFORMS)))

.PHONY: container
container: $(BUILD_DIRS)
	@echo "container: $(IMAGE):$(VERSION)"
	@rm -rf bin/.dockerfile;                                              \
	sed                                                                   \
	    -e 's|{ELASTICSEARCH_DASHBOARD_IMAGE}|$(DASHBOARD_IMAGE)|g'       \
	    Dockerfile > bin/.dockerfile;                                     \
	# ref: https://superuser.com/a/842705
	tar -czh . | docker buildx build --platform $(PLATFORM) --load --pull -t $(IMAGE):$(VERSION) -f bin/.dockerfile -
	@echo

push: container
	@docker push $(IMAGE):$(VERSION)
	@echo "pushed: $(IMAGE):$(VERSION)"
	@echo

.PHONY: docker-manifest
docker-manifest:
	docker manifest create -a $(IMAGE):$(TAG) $(foreach PLATFORM,$(DOCKER_PLATFORMS),$(IMAGE):$(TAG)_$(subst /,_,$(PLATFORM)))
	docker manifest push $(IMAGE):$(TAG)

.PHONY: release
release:
	@$(MAKE) all-push docker-manifest --no-print-directory

.PHONY: version
version:
	@echo ::set-output name=version::$(VERSION)

.PHONY: fmt
fmt:
	@find ./.. -path ./vendor -prune -o -name '*.sh' -exec shfmt -l -w -ci -i 4 {} \;

.PHONY: verify
verify: fmt
	@if !(git diff --exit-code HEAD); then \
		echo "files are out of date, run make fmt"; exit 1; \
	fi

.PHONY: ci
ci: verify
