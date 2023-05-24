ifneq (,$(wildcard .env))
	include .env
  export
endif

GOOS = $(shell go env GOOS)
export GOOS
GOARCH = $(shell go env GOARCH)
export GOARCH
GOARM = $(shell go env GOARM)
export GOARM

ifeq ($(OS),Windows_NT)
BIN := gitlab-download-release.exe
BINDIR = c:\windows\system32
else
BIN := gitlab-download-release
BINDIR = /usr/local/bin
endif

CGO_ENABLED := 0
export CGO_ENABLED

ifneq ($(OS),Windows_NT)
VERSION ?= $(shell ( git describe --tags --exact-match 2>/dev/null || ( git describe --tags 2>/dev/null || echo "0.0.0-0-g$$(git rev-parse --short=8 HEAD)" ) | sed 's/-[0-9][0-9]*-g/-SNAPSHOT-/') | sed 's/^v//' )
else
VERSION ?= dev
endif

.PHONY: build
build: ## Build app binary for single target
	$(call print-target)
	go build -ldflags="-s -w -X main.version=$(VERSION)"

$(BIN):
	@$(MAKE) build

.PHONY: goreleaser
goreleaser: ## Build app binary for all targets
	$(call print-target)
	goreleaser release --auto-snapshot --clean --skip-publish

.PHONY: install
install: ## Build and install app binary
install: $(BIN)
	$(call print-target)
ifeq ($(OS),Windows_NT)
	install $(BIN) $(BINDIR)
else
	powershell -Command "Copy-Item -Path '$(BIN)' -Destination '$(BINDIR)'"
endif

.PHONY: uninstall
uninstall: ## Uninstall app binary
uninstall: download
ifeq ($(OS),Windows_NT)
	-powershell -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue '$(BINDIR)\$(BIN)'"
else
	rm -f $(BINDIR)/$(BIN)
endif

.PHONY: download
download: ## Download Go modules
	$(call print-target)
	go mod download

.PHONY: tidy
tidy: ## Tidy Go modules
	$(call print-target)
	go mod tidy

.PHONY: upgrade
upgrade: ## Upgrade Go modules
	$(call print-target)
	go get -u

.PHONY: clean
clean: ## Clean working directory
ifeq ($(OS),Windows_NT)
	-powershell -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 'dist', '$(BIN)'"
else
	rm -rf dist $(BIN)
endif

ifneq ($(OS),Windows_NT)
VERSION ?= $(shell ( git describe --tags --exact-match 2>/dev/null || ( git describe --tags 2>/dev/null || echo "0.0.0-0-g$$(git rev-parse --short=8 HEAD)" ) | sed 's/-[0-9][0-9]*-g/-SNAPSHOT-/') | sed 's/^v//' )

.PHONY: version
version: ## Show version
	@echo "$(VERSION)"

DOCKERFILE ?= Dockerfile
IMAGE_NAME ?= gitlab-download-release
LOCAL_REPO ?= localhost:5000/$(IMAGE_NAME)
DOCKER_REPO ?= localhost:5000/$(IMAGE_NAME)

ifeq ($(shell uname -m),arm64)
PLATFORM ?= linux/arm64
else ifeq ($(shell uname -m),aarch64)
PLATFORM ?= linux/arm64
else
PLATFORM ?= linux/amd64
endif

.PHONY: image
image: ## Build a local image without publishing artifacts.
	$(call print-target)
	docker buildx build --file=$(DOCKERFILE) \
	--platform=$(PLATFORM) \
	--build-arg VERSION=$(VERSION) \
	--build-arg REVISION=$(shell git rev-parse HEAD) \
	--build-arg BUILDDATE=$(shell TZ=GMT date '+%Y-%m-%dT%R:%S.%03NZ') \
	--tag $(LOCAL_REPO) \
	--load \
	.

.PHONY: push
push: ## Publish to container registry.
	$(call print-target)
	docker tag $(LOCAL_REPO) $(DOCKER_REPO):$(VERSION)-$(subst /,-,$(PLATFORM))
	docker push $(DOCKER_REPO):$(VERSION)-$(subst /,-,$(PLATFORM))

.PHONY: test-image
test-image: ## Test local image
	$(call print-target)
	docker run --platform=$(PLATFORM) --rm -t $(LOCAL_REPO) -v | grep version
endif

.PHONY: help
help:
	@echo Targets:
ifeq ($(OS),Windows_NT)
	@powershell -Command "Get-Content $(MAKEFILE_LIST) | ForEach-Object { if ($$_ -match '^[a-zA-Z0-9._-]+:.*?## ') { $$match = $$_ -split ':.*?## '; '{0,-20} {1}' -f $$match[0], $$match[1] } } | Sort-Object"
else
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
endif

ifeq ($(OS),Windows_NT)
define print-target
	@echo Executing target: $@
endef
else
define print-target
	@printf "Executing target: \033[36m$@\033[0m\n"
endef
endif
