ifneq (,$(wildcard .env))
	include .env
  export
endif

ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

GOROOT := $(shell go env GOROOT)

ifeq ($(OS),Windows_NT)
BIN := gitlab-download-release.exe
BINDIR = c:\windows\system32
else
BIN := gitlab-download-release
BINDIR = /usr/local/bin
endif

.PHONY: build
build: ## Build app binary for single target
build:
	$(call print-target)
	go build -ldflags="-s -w"

$(BIN):
	@$(MAKE) build

.PHONY: goreleaser
goreleaser: ## Build app binary for all targets
goreleaser:
	$(call print-target)
	goreleaser build --clean --snapshot

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

.PHONY: tidy
tidy: ## Tidy Go modules
tidy:
	$(call print-target)
	go mod tidy

.PHONY: upgrade
upgrade: ## Upgrade Go modules
upgrade:
	$(call print-target)
	go get -u

.PHONY: clean
clean: ## Clean working directory
clean:
ifeq ($(OS),Windows_NT)
	-powershell -Command "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 'dist', '$(BIN)'"
else
	rm -rf dist $(BIN)
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
