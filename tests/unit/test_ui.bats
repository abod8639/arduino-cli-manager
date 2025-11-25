#!/usr/bin/env bats

# Tests for ui.sh module

load '../helpers/assertions'

setup() {
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/ui.sh"
}

@test "print_logo outputs ASCII art" {
    run print_logo
    
    assert_output_contains "██████╗"
    assert_output_contains "ARDUINO"
}

@test "print_header clears screen and shows logo" {
    run print_header
    
    assert_output_contains "ARDUINO CLI MANAGER"
    assert_output_contains "Project:"
    assert_output_contains "Board:"
    assert_output_contains "Port:"
}

@test "get_version_line shows version" {
    run get_version_line
    
    assert_output_contains "$VERSION"
}

@test "get_version_line shows update notification" {
    LATEST_VERSION="9.9.9"
    VERSION="1.0.0"
    
    run get_version_line
    
    assert_output_contains "Update available"
}

@test "show_help displays help text" {
    run show_help
    
    assert_output_contains "Quick Help"
    assert_output_contains "Getting Started"
    assert_output_contains "Keyboard Shortcuts"
}

@test "show_help includes all shortcuts" {
    run show_help
    
    assert_output_contains "S - Select/Create Project"
    assert_output_contains "B - Select Board"
    assert_output_contains "C - Compile"
    assert_output_contains "U - Upload"
}
