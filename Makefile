# Copyright 2024 HAMi Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build configuration
BINARY_NAME     := hami
CMD_DIR         := ./cmd
OUTPUT_DIR      := ./bin
GO              := go
GOFLAGS         ?=
GOOS            ?= linux
GOARCH          ?= amd64
CGO_ENABLED     ?= 0

# Version information
VERSION         ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GIT_COMMIT      ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE      ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Docker configuration
# Personal fork: using my own registry instead of the upstream ghcr.io/hami-project
REGISTRY        ?= ghcr.io/my-username
IMAGE_NAME      ?= hami
IMAGE_TAG       ?= $(VERSION)
FULL_IMAGE      := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# LDFLAGS for embedding version info
LDFLAGS := -ldflags "-X main.version=$(VERSION) \
	-X main.gitCommit=$(GIT_COMMIT) \
	-X main.buildDate=$(BUILD_DATE) \
	-s -w"

.PHONY: all build clean test lint fmt vet docker-build docker-push help

## all: Build all binaries
all: build

## build: Compile the project binaries
build:
	@echo "Building $(BINARY_NAME) version=$(VERSION) commit=$(GIT_COMMIT)"
	@mkdir -p $(OUTPUT_DIR)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		$(GO) build $(GOFLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME) $(CMD_DIR)/...

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)
	@$(GO) clean -cache

## test: Run unit tests
test:
	@echo "Running tests..."
	$(GO) test ./... -v -race -count=1 -timeout=120s

## test-coverage: Run tests with coverage report
test-coverage:
	@echo "Running tests with coverage..."
	$(GO) test ./... -coverprofile=coverage.out -covermode=atomic
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

## lint: Run golangci-lint
lint:
	@echo "Running linter..."
	@which golangci-lint > /dev/null 2>&1 || (echo "golangci-lint not found, installing..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin)
	golangci-lint run ./...

## fmt: Format Go source code
fmt:
	@echo "Formatting code..."
	$(GO) fmt ./...

## vet: Run go vet
vet:
	@echo "Running go vet..."
	$(GO) vet ./...

## tidy: Tidy go modules
tidy:
	@echo "Tidying modules..."
	$(GO) mod tidy

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image $(FULL_IMAGE)..."
	docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_COMMIT=$(GIT_COMMI
