SHELL=/bin/bash -o pipefail

SOURCE_IMAGE_REF := kubedb/elasticsearch-init:7.14.0-xpack-v2021.08.14

REGISTRY     ?= ghcr.io/kubedb
BIN          := elasticsearch
IMAGE        := $(REGISTRY)/$(BIN)
TAG          := $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

.PHONY: push
push:
	docker pull $(SOURCE_IMAGE_REF)
	docker tag $(SOURCE_IMAGE_REF) $(IMAGE):$(TAG)
	docker push $(IMAGE):$(TAG)

.PHONY: version
version:
	@echo ::set-output name=version::$(TAG)