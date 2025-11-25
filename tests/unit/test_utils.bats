#!/usr/bin/env bats

# Tests for utils.sh module

load '../helpers/assertions'
load '../helpers/mocks'

setup() {
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
}

@test "vercmp_portable: equal versions" {
    run vercmp_portable "1.0.0" "1.0.0"
    [ "$status" -eq 0 ]
}

@test "vercmp_portable: first version greater" {
    run vercmp_portable "2.0.0" "1.0.0"
    [ "$status" -eq 1 ]
}

@test "vercmp_portable: second version greater" {
    run vercmp_portable "1.0.0" "2.0.0"
    [ "$status" -eq 2 ]
}

@test "save_config creates config file" {
    FQBN="test:board:uno"
    PORT="/dev/ttyACM0"
    BAUD="115200"
    
    run save_config
    assert_file_exists "$CONFIG_FILE"
}

@test "save_config writes correct values" {
    FQBN="test:board:uno"
    PORT="/dev/ttyACM0"
    BAUD="115200"
    
    save_config
    
    grep -q "FQBN='test:board:uno'" "$CONFIG_FILE"
    grep -q "PORT='/dev/ttyACM0'" "$CONFIG_FILE"
    grep -q "BAUD='115200'" "$CONFIG_FILE"
}

@test "load_config reads valid config" {
    echo "FQBN='test:board:uno'" > "$CONFIG_FILE"
    echo "PORT='/dev/ttyACM0'" >> "$CONFIG_FILE"
    echo "BAUD='115200'" >> "$CONFIG_FILE"
    
    run load_config
    
    [ "$FQBN" = "test:board:uno" ]
    [ "$PORT" = "/dev/ttyACM0" ]
    [ "$BAUD" = "115200" ]
}

@test "load_config rejects malicious config" {
    echo "FQBN='test'; rm -rf /" > "$CONFIG_FILE"
    
    run load_config
    
    # Should not execute the malicious command
    [ -d "$TEST_TEMP_DIR" ]  # Directory still exists
}

@test "backup_project creates backup file" {
    local test_project="$SKETCH_DIR/test_project1"
    
    run backup_project "$test_project"
    
    # Check if backup was created
    local backup_count=$(ls -1 "$BACKUP_DIR"/test_project1_*.tar.gz 2>/dev/null | wc -l)
    [ "$backup_count" -ge 1 ]
}

@test "backup_project keeps only 5 backups" {
    local test_project="$SKETCH_DIR/test_project1"
    
    # Create 7 backups
    for i in {1..7}; do
        sleep 1  # Ensure different timestamps
        backup_project "$test_project"
    done
    
    # Should only have 5 backups
    local backup_count=$(ls -1 "$BACKUP_DIR"/test_project1_*.tar.gz 2>/dev/null | wc -l)
    [ "$backup_count" -eq 5 ]
}

@test "log_operation creates log file" {
    run log_operation "TEST" "SUCCESS" "test details"
    
    assert_file_exists "$LOG_FILE"
}

@test "log_operation writes correct format" {
    log_operation "TEST" "SUCCESS" "test details"
    
    grep -q "TEST - SUCCESS - test details" "$LOG_FILE"
}

@test "log_operation includes timestamp" {
    log_operation "TEST" "SUCCESS" "test details"
    
    # Check for timestamp format [YYYY-MM-DD HH:MM:SS]
    grep -q "\\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\\]" "$LOG_FILE"
}
