SHELL=/bin/bash -o pipefail

SOURCE_IMAGE_REF := floragunncom/sg-elasticsearch:7.3.2-oss-37.0.0

REGISTRY     ?= kubedb
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