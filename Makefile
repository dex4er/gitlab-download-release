ifneq (,$(wildcard ./.env))
	include .env
  export
endif

ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

GOROOT := $(shell go env GOROOT)

BIN := gitlab-download-release

BINDIR = /usr/local/bin

.PHONY: build
build: ## Build app binary for single target
build:
	$(call print-target)
	goreleaser build --clean --snapshot --single-target --output $(BIN)

$(BIN):
	@$(MAKE) build

.PHONY: build-all-targets
build-all-targets: ## Build app binary for all targets
build-all-targets:
	$(call print-target)
	goreleaser build --clean --snapshot

.PHONY: install
install: ## Build and install app binary
install: $(BIN)
	$(call print-target)
	install $(BIN) $(BINDIR)

.PHONY: uninstall
uninstall: ## Uninstall app binary
uninstall: download
	rm -f $(BINDIR)/$(BIN)

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
	rm -rf dist $(BIN)

.PHONY: help
help:
	@echo "$(BIN)"
	@echo
	@echo Targets:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

define print-target
	@printf "Executing target: \033[36m$@\033[0m\n"
endef
