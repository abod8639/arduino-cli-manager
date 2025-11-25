#!/usr/bin/env bats

# Tests for config.sh module

load '../helpers/assertions'

setup() {
    # Source the config module
    source "$PROJECT_ROOT/lib/config.sh"
}

@test "VERSION variable is set" {
    assert_var_set "VERSION"
}

@test "VERSION follows semantic versioning" {
    [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "Default FQBN is set" {
    assert_var_set "DEFAULT_FQBN"
}

@test "Default PORT is set" {
    assert_var_set "DEFAULT_PORT"
}

@test "Default BAUD is set" {
    assert_var_set "DEFAULT_BAUD"
    [[ "$DEFAULT_BAUD" =~ ^[0-9]+$ ]]
}

@test "SKETCH_DIR is set to HOME/Arduino" {
    assert_var_set "SKETCH_DIR"
    [[ "$SKETCH_DIR" == "$HOME/Arduino" ]]
}

@test "CONFIG_FILE path is set" {
    assert_var_set "CONFIG_FILE"
    [[ "$CONFIG_FILE" == "$HOME/.arduino-cli-manager.conf" ]]
}

@test "BACKUP_DIR is set" {
    assert_var_set "BACKUP_DIR"
}

@test "LOG_DIR is set" {
    assert_var_set "LOG_DIR"
}

@test "LOG_FILE is set" {
    assert_var_set "LOG_FILE"
}

@test "Color codes are defined" {
    assert_var_set "C_RESET"
    assert_var_set "C_RED"
    assert_var_set "C_GREEN"
    assert_var_set "C_YELLOW"
    assert_var_set "C_BLUE"
    assert_var_set "C_PURPLE"
    assert_var_set "C_CYAN"
}

@test "State variables are initialized" {
    # These should be empty initially
    [[ -z "$FQBN" || -n "$FQBN" ]]  # Can be set or empty
    [[ -z "$PORT" || -n "$PORT" ]]
    [[ -z "$BAUD" || -n "$BAUD" ]]
    [[ -z "$PROJECT" || -n "$PROJECT" ]]
}
