#!/usr/bin/env bash

# Global test cleanup - runs once after all tests

# Remove temporary test directory
if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
    echo "Cleaned up test directory: $TEST_TEMP_DIR"
fi
