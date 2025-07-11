#!/bin/bash

# Default configuration
BOARD_FQBN="${BOARD_FQBN:-esp32:esp32:esp32}"
PORT="${PORT:-/dev/ttyACM0}"
SKETCH_NAME="my_arduino_project"

# Compile the sketch
arduino-cli compile --fqbn "$BOARD_FQBN" "$SKETCH_NAME"

# Upload the sketch
arduino-cli upload -p "$PORT" --fqbn "$BOARD_FQBN" "$SKETCH_NAME"
