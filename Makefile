SHELL=/bin/bash -o pipefail

REGISTRY   ?= kubedb
BIN        := elasticsearch
IMAGE      := $(REGISTRY)/$(BIN)
DB_VERSION := 7.3.2
TAG        := $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

.PHONY: push
push: container
	docker push $(IMAGE):$(TAG)

.PHONY: container
container:
	docker pull docker.elastic.co/elasticsearch/elasticsearch:$(DB_VERSION)
	docker tag docker.elastic.co/elasticsearch/elasticsearch:$(DB_VERSION) $(IMAGE):$(TAG)

.PHONY: version
version:
	@echo ::set-output name=version::$(TAG)
