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

POWERSHELL_FLAGS = -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Unrestricted

ifeq ($(findstring pwsh,$(SHELL)),pwsh)
USE_POWERSHELL = yes
POWERSHELL = $(SHELL)
.SHELLFLAGS = $(POWERSHELL_FLAGS)
else ifeq ($(findstring powershell,$(SHELL)),powershell)
USE_POWERSHELL = yes
POWERSHELL = $(SHELL)
.SHELLFLAGS = $(POWERSHELL_FLAGS)
else
USE_POWERSHELL = no
endif

ifeq ($(OS),Windows_NT)
BIN := gitlab-download-release.exe
ifneq (,$(LOCALAPPDATA))
BINDIR = $(LOCALAPPDATA)\Microsoft\WindowsApps
else
BINDIR = C:\Windows\System32
endif
else
BIN := gitlab-download-release
ifneq (,$(wildcard $(HOME)/.local/bin))
BINDIR = $(HOME)/.local/bin
else ifneq (,$(wildcard $(HOME)/bin))
BINDIR = $(HOME)/bin
else
BINDIR = /usr/local/bin
endif
endif

CGO_ENABLED := 0
export CGO_ENABLED

ifeq ($(USE_POWERSHELL),yes)
VERSION ?= $(shell $(POWERSHELL) $(POWERSHELL_FLAGS) -EncodedCommand dAByAHkAIAB7ACAAJABlAHgAYQBjAHQATQBhAHQAYwBoACAAPQAgAGcAaQB0ACAAZABlAHMAYwByAGkAYgBlACAALQAtAHQAYQBnAHMAIAAtAC0AZQB4AGEAYwB0AC0AbQBhAHQAYwBoACAAMgA+ACQAbgB1AGwAbAA7ACAAaQBmACAAKAAtAG4AbwB0ACAAWwBzAHQAcgBpAG4AZwBdADoAOgBJAHMATgB1AGwAbABPAHIARQBtAHAAdAB5ACgAJABlAHgAYQBjAHQATQBhAHQAYwBoACkAKQAgAHsAIAAkAHYAZQByAHMAaQBvAG4AIAA9ACAAJABlAHgAYQBjAHQATQBhAHQAYwBoACAAfQAgAGUAbABzAGUAIAB7ACAAJAB0AGEAZwBzACAAPQAgAGcAaQB0ACAAZABlAHMAYwByAGkAYgBlACAALQAtAHQAYQBnAHMAIAAyAD4AJABuAHUAbABsADsAIABpAGYAIAAoAFsAcwB0AHIAaQBuAGcAXQA6ADoASQBzAE4AdQBsAGwATwByAEUAbQBwAHQAeQAoACQAdABhAGcAcwApACkAIAB7ACAAJABjAG8AbQBtAGkAdABIAGEAcwBoACAAPQAgACgAZwBpAHQAIAByAGUAdgAtAHAAYQByAHMAZQAgAC0ALQBzAGgAbwByAHQAPQA4ACAASABFAEEARAApAC4AVAByAGkAbQAoACkAOwAgACQAdgBlAHIAcwBpAG8AbgAgAD0AIAAiADAALgAwAC4AMAAtADAALQBnACQAYwBvAG0AbQBpAHQASABhAHMAaAAiACAAfQAgAGUAbABzAGUAIAB7ACAAJAB2AGUAcgBzAGkAbwBuACAAPQAgACQAdABhAGcAcwAgAC0AcgBlAHAAbABhAGMAZQAgACcALQBbADAALQA5AF0AWwAwAC0AOQBdACoALQBnACcALAAgACcALQBTAE4AQQBQAFMASABPAFQALQAnACAAfQAgAH0AOwAgACQAdgBlAHIAcwBpAG8AbgAgAD0AIAAkAHYAZQByAHMAaQBvAG4AIAAtAHIAZQBwAGwAYQBjAGUAIAAnAF4AdgAnACwAIAAnACcAOwAgAFcAcgBpAHQAZQAtAE8AdQB0AHAAdQB0ACAAJAB2AGUAcgBzAGkAbwBuACAAfQAgAGMAYQB0AGMAaAAgAHsAIABXAHIAaQB0AGUALQBPAHUAdABwAHUAdAAgACIAMAAuADAALgAwACIAIAB9AAoA)
REVISION ?= $(shell git rev-parse HEAD)
BUILDDATE ?= $(shell $(POWERSHELL) $(POWERSHELL_FLAGS) -EncodedCommand JABkAGEAdABlAHQAaQBtAGUAIAA9ACAARwBlAHQALQBEAGEAdABlADsAIAAkAHUAdABjACAAPQAgACQAZABhAHQAZQB0AGkAbQBlAC4AVABvAFUAbgBpAHYAZQByAHMAYQBsAFQAaQBtAGUAKAApADsAIAAkAHUAdABjAC4AdABvAHMAdAByAGkAbgBnACgAIgB5AHkAeQB5AC0ATQBNAC0AZABkAFQASABIADoAbQBtADoAcwBzAFoAIgApAAoA)
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
	$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "Copy-Item -Path '$(BIN)' -Destination '$(BINDIR)'"
else
	$(INSTALL) $(BIN) $(BINDIR)
endif

.PHONY: uninstall
uninstall: ## Uninstall app binary
uninstall: download
ifeq ($(USE_POWERSHELL),yes)
	-$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue '$(BINDIR)\$(BIN)'"
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
	-$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 'dist', '$(BIN)'"
else
	$(RM) -rf dist $(BIN)
endif

.PHONY: version
version: ## Show version
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "echo $(VERSION)"
else
	@$(ECHO) "$(VERSION)"
endif

.PHONY: revision
revision: ## Show revision
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "echo $(REVISION)"
else
	@$(ECHO) "$(REVISION)"
endif

.PHONY: builddate
builddate: ## Show build date
ifeq ($(USE_POWERSHELL),yes)
	@$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "echo $(BUILDDATE)"
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
	@$(POWERSHELL) $(POWERSHELL_FLAGS) -EncodedCommand RwBlAHQALQBDAG8AbgB0AGUAbgB0ACAATQBhAGsAZQBmAGkAbABlACAAfAAgAEYAbwByAEUAYQBjAGgALQBPAGIAagBlAGMAdAAgAHsAIABpAGYAIAAoACQAXwAgAC0AbQBhAHQAYwBoACAAJwBeAFsAYQAtAHoAQQAtAFoAMAAtADkALgBfAC0AXQArADoALgAqAD8AIwAjACAAJwApACAAewAgACQAbQBhAHQAYwBoACAAPQAgACQAXwAgAC0AcwBwAGwAaQB0ACAAJwA6AC4AKgA/ACMAIwAgACcAOwAgACcAIAAgAHsAMAAsAC0AMgAwAH0AIAB7ADEAfQAnACAALQBmACAAJABtAGEAdABjAGgAWwAwAF0ALAAgACQAbQBhAHQAYwBoAFsAMQBdACAAfQAgAH0AIAB8ACAAUwBvAHIAdAAtAE8AYgBqAGUAYwB0AAoA
else
	@$(AWK) 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | $(SORT)
endif

ifeq ($(USE_POWERSHELL),yes)
define print-target
	@$(POWERSHELL) $(POWERSHELL_FLAGS) -Command "echo 'Executing target: $@'"
endef
else
define print-target
	@$(PRINTF) "Executing target: \033[36m$@\033[0m\n"
endef
endif
