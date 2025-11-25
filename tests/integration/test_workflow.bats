#!/usr/bin/env bats

# Integration tests - End-to-end workflows

load '../helpers/assertions'
load '../helpers/mocks'

setup() {
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/ui.sh"
    source "$PROJECT_ROOT/lib/projects.sh"
    source "$PROJECT_ROOT/lib/libraries.sh"
    source "$PROJECT_ROOT/lib/arduino.sh"
}

@test "All modules load without errors" {
    # If we got here, all modules loaded successfully
    [ "$?" -eq 0 ]
}

@test "Config is saved and loaded correctly" {
    # Set some values
    FQBN="esp32:esp32:esp32"
    PORT="/dev/ttyUSB0"
    BAUD="115200"
    
    # Save config
    save_config
    
    # Clear values
    FQBN=""
    PORT=""
    BAUD=""
    
    # Load config
    load_config
    
    # Verify values were restored
    [ "$FQBN" = "esp32:esp32:esp32" ]
    [ "$PORT" = "/dev/ttyUSB0" ]
    [ "$BAUD" = "115200" ]
}

@test "Backup and log workflow" {
    local test_project="$SKETCH_DIR/test_project1"
    
    # Create backup
    backup_project "$test_project"
    
    # Verify backup exists
    local backup_count=$(ls -1 "$BACKUP_DIR"/test_project1_*.tar.gz 2>/dev/null | wc -l)
    [ "$backup_count" -ge 1 ]
    
    # Verify log entry
    grep -q "BACKUP - SUCCESS - test_project1" "$LOG_FILE"
}

@test "Version comparison works correctly" {
    # Test various version comparisons
    run vercmp_portable "1.0.0" "1.0.0"
    [ "$status" -eq 0 ]
    
    run vercmp_portable "2.0.0" "1.0.0"
    [ "$status" -eq 1 ]
    
    run vercmp_portable "1.0.0" "2.0.0"
    [ "$status" -eq 2 ]
    
    run vercmp_portable "1.0.10" "1.0.9"
    [ "$status" -eq 1 ]
}

@test "All critical functions are defined" {
    # Config functions
    assert_function_exists "save_config"
    assert_function_exists "load_config"
    
    # Utils functions
    assert_function_exists "check_dependencies"
    assert_function_exists "backup_project"
    assert_function_exists "log_operation"
    
    # UI functions
    assert_function_exists "print_header"
    assert_function_exists "show_help"
    
    # Projects functions
    assert_function_exists "select_or_create_project"
    assert_function_exists "browse_custom_path"
    
    # Libraries functions
    assert_function_exists "manage_libraries"
    
    # Arduino functions
    assert_function_exists "compile_sketch"
    assert_function_exists "upload_sketch"
}
