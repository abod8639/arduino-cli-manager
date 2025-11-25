SHELL := /bin/bash

# Default configuration
BOARD_FQBN ?= esp32:esp32:esp32
PORT ?= /dev/ttyACM1
SKETCH_NAME = my_arduino_project

.PHONY: all compile upload build monitor clean

all: build

compile:
	@echo "Compiling for $(BOARD_FQBN)..."
	@arduino-cli compile --fqbn "$(BOARD_FQBN)" "$(SKETCH_NAME)"

upload:
	@echo "Uploading to $(PORT)..."
	@arduino-cli upload -p "$(PORT)" --fqbn "$(BOARD_FQBN)" "$(SKETCH_NAME)"

build: compile upload

monitor:
	@echo "Opening serial monitor on $(PORT)..."
	@arduino-cli monitor -p "$(PORT)"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build

# ===== Testing Targets =====

.PHONY: help-test test test-unit test-integration test-all install-test-deps test-clean

help-test:
	@echo "Testing Commands:"
	@echo "  make install-test-deps  - Install testing dependencies (bats)"
	@echo "  make test              - Run all tests"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make test-integration  - Run integration tests only"
	@echo "  make test-verbose      - Run tests with verbose output"
	@echo "  make test-clean        - Clean test artifacts"
	@echo ""

install-test-deps:
	@echo "Installing bats-core..."
	@if command -v npm > /dev/null; then \
		npm install -g bats; \
	elif command -v brew > /dev/null; then \
		brew install bats-core; \
	else \
		echo "Please install bats manually: https://github.com/bats-core/bats-core"; \
		exit 1; \
	fi
	@echo "✓ Testing dependencies installed"

test: test-unit test-integration
	@echo "✓ All tests completed"

test-unit:
	@echo "Running unit tests..."
	@bats tests/unit/*.bats

test-integration:
	@echo "Running integration tests..."
	@bats tests/integration/*.bats

test-verbose:
	@echo "Running all tests (verbose)..."
	@bats -t tests/unit/*.bats tests/integration/*.bats

test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=tests/unit/test_config.bats"; \
		exit 1; \
	fi
	@bats $(FILE)

test-clean:
	@echo "Cleaning test artifacts..."
	@rm -rf tests/tmp
	@echo "✓ Test artifacts cleaned"
