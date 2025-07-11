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
