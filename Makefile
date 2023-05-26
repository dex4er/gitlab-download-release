ifneq (,$(wildcard .env))
	include .env
  export
endif

AWK = awk
DOCKER = docker
ECHO = echo
GO = go
GORELEASER = goreleaser
INSTALL = install
POWERSHELL = powershell
PRINTF = printf
RM = rm
SORT = sort

ifeq ($(findstring pwsh,$(SHELL)),pwsh)
USE_POWERSHELL = yes
else ifeq ($(findstring powershell,$(SHELL)),powershell)
USE_POWERSHELL = yes
else
USE_POWERSHELL = no
endif

ifeq ($(USE_POWERSHELL),yes)
POWERSHELL = $(SHELL)
endif

GOOS = $(shell go env GOOS)
export GOOS
GOARCH = $(shell go env GOARCH)
export GOARCH

ifeq ($(OS),Windows_NT)
BIN := gitlab-download-release.exe
BINDIR = c:\windows\system32
else
BIN := gitlab-download-release
BINDIR = /usr/local/bin
endif

CGO_ENABLED := 0
export CGO_ENABLED

ifeq ($(USE_POWERSHELL),yes)
VERSION ?= $(shell $(POWERSHELL) -Command "echo dHJ5IHsgJGV4YWN0TWF0Y2ggPSBnaXQgZGVzY3JpYmUgLS10YWdzIC0tZXhhY3QtbWF0Y2ggMj4kbnVsbDsgaWYgKC1ub3QgW3N0cmluZ106OklzTnVsbE9yRW1wdHkoJGV4YWN0TWF0Y2gpKSB7ICR2ZXJzaW9uID0gJGV4YWN0TWF0Y2ggfSBlbHNlIHsgJHRhZ3MgPSBnaXQgZGVzY3JpYmUgLS10YWdzIDI+JG51bGw7IGlmIChbc3RyaW5nXTo6SXNOdWxsT3JFbXB0eSgkdGFncykpIHsgJGNvbW1pdEhhc2ggPSAoZ2l0IHJldi1wYXJzZSAtLXNob3J0PTggSEVBRCkuVHJpbSgpOyAkdmVyc2lvbiA9ICIwLjAuMC0wLWckY29tbWl0SGFzaCIgfSBlbHNlIHsgJHZlcnNpb24gPSAkdGFncyAtcmVwbGFjZSAnLVswLTldWzAtOV0qLWcnLCAnLVNOQVBTSE9ULScgfSB9OyAkdmVyc2lvbiA9ICR2ZXJzaW9uIC1yZXBsYWNlICdedicsICcnOyBXcml0ZS1PdXRwdXQgJHZlcnNpb24gfSBjYXRjaCB7IFdyaXRlLU91dHB1dCAiMC4wLjAiIH0K | $(POWERSHELL) -NoProfile -NonInteractive -Command '[Text.Encoding]::Utf8.GetString([Convert]::FromBase64String(`$$input)) | iex'")
REVISION ?= $(shell git rev-parse HEAD)
BUILDDATE ?= $(shell $(POWERSHELL) -Command "echo JGRhdGV0aW1lID0gR2V0LURhdGU7ICR1dGMgPSAkZGF0ZXRpbWUuVG9Vbml2ZXJzYWxUaW1lKCk7ICR1dGMudG9zdHJpbmcoInl5eXktTU0tZGRUSEg6bW06c3NaIikK | $(POWERSHELL) -NoProfile -NonInteractive -Command '[Text.Encoding]::Utf8.GetString([Convert]::FromBase64String(`$$input)) | iex'")
else
VERSION ?= $(shell ( git describe --tags --exact-match 2>/dev/null || ( git describe --tags 2>/dev/null || echo "0.0.0-0-g$$(git rev-parse --short=8 HEAD)" ) | sed 's/-[0-9][0-9]*-g/-SNAPSHOT-/') | sed 's/^v//' )
REVISION ?= $(shell git rev-parse HEAD)
BUILDDATE ?= $(shell TZ=GMT date '+%Y-%m-%dT%R:%SZ')
endif

.PHONY: build
build: ## Build app binary for single target
	$(call print-target)
	$(GO) build -trimpath -ldflags="-s -w -X main.version=$(VERSION)"

$(BIN):
	@$(MAKE) build

.PHONY: goreleaser
goreleaser: ## Build app binary for all targets
	$(call print-target)
	$(GORELEASER) release --auto-snapshot --clean --skip-publish

.PHONY: install
install: ## Build and install app binary
install: $(BIN)
	$(call print-target)
ifeq ($(USE_POWERSHELL),yes)
	$(POWERSHELL) -Command "Copy-Item -Path '$(BIN)' -Destination '$(BINDIR)'"
else
	$(INSTALL) $(BIN) $(BINDIR)
endif

.PHONY: uninstall
uninstall: ## Uninstall app binary
uninstall: download
ifeq ($(USE_POWERSHELL),yes)
	-$(POWERSHELL) -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue '$(BINDIR)\$(BIN)'"
else
	$(RM) -f $(BINDIR)/$(BIN)
endif

.PHONY: download
download: ## Download Go modules
	$(call print-target)
	$(GO) mod download

.PHONY: tidy
tidy: ## Tidy Go modules
	$(call print-target)
	$(GO) mod tidy

.PHONY: upgrade
upgrade: ## Upgrade Go modules
	$(call print-target)
	$(GO) get -u

.PHONY: clean
clean: ## Clean working directory
ifeq ($(USE_POWERSHELL),yes)
	-$(POWERSHELL) -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 'dist', '$(BIN)'"
else
	$(RM) -rf dist $(BIN)
endif

.PHONY: version
version: ## Show version
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) -Command "echo $(VERSION)"
else
	@$(ECHO) "$(VERSION)"
endif

.PHONY: revision
revision: ## Show revision
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) -Command "echo $(REVISION)"
else
	@$(ECHO) "$(REVISION)"
endif

.PHONY: builddate
builddate: ## Show build date
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) -Command "echo $(BUILDDATE)"
else
	@$(ECHO) "$(BUILDDATE)"
endif

DOCKERFILE ?= Dockerfile
IMAGE_NAME ?= gitlab-download-release
LOCAL_REPO ?= localhost:5000/$(IMAGE_NAME)
DOCKER_REPO ?= localhost:5000/$(IMAGE_NAME)

ifeq ($(PROCESSOR_ARCHITECTURE),ARM64)
PLATFORM = linux/arm64
else ifeq ($(shell uname -m),arm64)
PLATFORM = linux/arm64
else ifeq ($(shell uname -m),aarch64)
PLATFORM = linux/arm64
else ifeq ($(findstring ARM64, $(shell uname -s)),ARM64)
PLATFORM = linux/arm64
else
PLATFORM = linux/amd64
endif

.PHONY: image
image: ## Build a local image without publishing artifacts.
	$(call print-target)
	$(DOCKER) buildx build --file=$(DOCKERFILE) \
	--platform=$(PLATFORM) \
	--build-arg VERSION=$(VERSION) \
	--build-arg REVISION=$(REVISION) \
	--build-arg BUILDDATE=$(BUILDDATE) \
	--tag $(LOCAL_REPO) \
	--load \
	.

.PHONY: push
push: ## Publish to container registry.
	$(call print-target)
	$(DOCKER) tag $(LOCAL_REPO) $(DOCKER_REPO):v$(VERSION)-$(subst /,-,$(PLATFORM))
	$(DOCKER) push $(DOCKER_REPO):v$(VERSION)-$(subst /,-,$(PLATFORM))

.PHONY: test-image
test-image: ## Test local image
	$(call print-target)
	$(DOCKER) run --platform=$(PLATFORM) --rm -t $(LOCAL_REPO) -v

.PHONY: help
help:
	@echo Targets:
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) -Command "Get-Content $(MAKEFILE_LIST) | ForEach-Object { if ($$_ -match '^[a-zA-Z0-9._-]+:.*?## ') { $$match = $$_ -split ':.*?## '; '  {0,-20} {1}' -f $$match[0], $$match[1] } } | Sort-Object"
else
	@$(AWK) 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | $(SORT)
endif

ifeq ($(USE_POWERSHELL),yes)
define print-target
	@$(POWERSHELL) -Command "echo 'Executing target: $@'"
endef
else
define print-target
	@$(PRINTF) "Executing target: \033[36m$@\033[0m\n"
endef
endif
