#!/usr/bin/env bash

# Global test setup - runs once before all tests

# Set test environment
export BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
export PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# Create temporary test directory
export TEST_TEMP_DIR="$(mktemp -d)"
export SKETCH_DIR="$TEST_TEMP_DIR/Arduino"
export CONFIG_FILE="$TEST_TEMP_DIR/.arduino-cli-manager.conf"
export BACKUP_DIR="$TEST_TEMP_DIR/backups"
export LOG_DIR="$TEST_TEMP_DIR/logs"
export LOG_FILE="$LOG_DIR/arduino-manager.log"

# Create test directories
mkdir -p "$SKETCH_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

# Create some test projects
mkdir -p "$SKETCH_DIR/test_project1"
echo "void setup() {}" > "$SKETCH_DIR/test_project1/test_project1.ino"
echo "void loop() {}" >> "$SKETCH_DIR/test_project1/test_project1.ino"

mkdir -p "$SKETCH_DIR/test_project2"
echo "void setup() {}" > "$SKETCH_DIR/test_project2/test_project2.ino"
echo "void loop() {}" >> "$SKETCH_DIR/test_project2/test_project2.ino"

# Load mocks
source "$BATS_TEST_DIRNAME/helpers/mocks.bash"

echo "Test environment setup complete"
echo "  TEST_TEMP_DIR: $TEST_TEMP_DIR"
echo "  SKETCH_DIR: $SKETCH_DIR"
