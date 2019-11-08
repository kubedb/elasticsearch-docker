SHELL=/bin/bash -o pipefail

REGISTRY ?= kubedb
BIN      := elasticsearch
IMAGE    := $(REGISTRY)/$(BIN)
BASE_TAG := 7.3.2
TAG      := $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

.PHONY: push
push: container
	docker push $(IMAGE):$(TAG)

.PHONY: container
container:
	docker pull $(IMAGE):$(BASE_TAG)
	docker tag $(IMAGE):$(BASE_TAG) $(IMAGE):$(TAG)

.PHONY: version
version:
	@echo ::set-output name=version::$(TAG)
