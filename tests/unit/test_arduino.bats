#!/usr/bin/env bats

# Tests for arduino.sh module

load '../helpers/assertions'
load '../helpers/mocks'

setup() {
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/ui.sh"
    source "$PROJECT_ROOT/lib/arduino.sh"
}

@test "list_all_supported_boards function exists" {
    assert_function_exists "list_all_supported_boards"
}

@test "select_board function exists" {
    assert_function_exists "select_board"
}

@test "select_port function exists" {
    assert_function_exists "select_port"
}

@test "compile_sketch function exists" {
    assert_function_exists "compile_sketch"
}

@test "compile_sketch requires project" {
    PROJECT=""
    
    run compile_sketch
    
    assert_output_contains "No project selected"
}

@test "upload_sketch function exists" {
    assert_function_exists "upload_sketch"
}

@test "open_serial function exists" {
    assert_function_exists "open_serial"
}

@test "list_installed_cores function exists" {
    assert_function_exists "list_installed_cores"
}

@test "install_core function exists" {
    assert_function_exists "install_core"
}

@test "update_script function exists" {
    assert_function_exists "update_script"
}
