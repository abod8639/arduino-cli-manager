#!/usr/bin/env bats

# Tests for libraries.sh module

load '../helpers/assertions'
load '../helpers/mocks'

setup() {
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/ui.sh"
    source "$PROJECT_ROOT/lib/libraries.sh"
}

@test "install_library function exists" {
    assert_function_exists "install_library"
}

@test "list_libraries function exists" {
    assert_function_exists "list_libraries"
}

@test "update_libraries function exists" {
    assert_function_exists "update_libraries"
}

@test "uninstall_library function exists" {
    assert_function_exists "uninstall_library"
}

@test "manage_libraries function exists" {
    assert_function_exists "manage_libraries"
}

# Note: Interactive functions are hard to test without user input
# These tests verify the functions exist and can be called
# Integration tests will cover actual functionality
