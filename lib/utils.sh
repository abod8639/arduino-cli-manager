#!/bin/bash

# Arduino CLI Manager - Utilities Module
# This file contains utility functions for config, logging, backup, and error handling

# --- Dependency Check ---
function check_dependencies() {
    if ! command -v arduino-cli &> /dev/null; then
        echo -e "${C_RED}Error: 'arduino-cli' is not installed or not in your PATH.${C_RESET}"
        echo "Please install it to use this script."
        echo "Installation instructions can be found at:"
        echo -e "${C_YELLOW}https://arduino.github.io/arduino-cli/latest/installation/${C_RESET}"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${C_YELLOW}Warning: 'jq' is not installed. Update checks will be skipped.${C_RESET}"
        echo "Please install 'jq' to enable automatic update notifications."
        echo "(e.g., 'sudo apt install jq' or 'brew install jq')"
        sleep 1
    fi
}

# --- Config Functions ---
function save_config() {
    echo "# Arduino CLI Manager Configuration" > "$CONFIG_FILE"
    echo "FQBN='${FQBN:-$DEFAULT_FQBN}'" >> "$CONFIG_FILE"
    echo "PORT='${PORT:-$DEFAULT_PORT}'" >> "$CONFIG_FILE"
    echo "BAUD='${BAUD:-$DEFAULT_BAUD}'" >> "$CONFIG_FILE"
}

function load_config() {
    # Load settings from the config file if it exists
    if [ -f "$CONFIG_FILE" ]; then
        # Validate config file contains only safe variable assignments
        # Check for valid format and no dangerous characters
        if grep -qE '^[A-Z_]+=' "$CONFIG_FILE" && ! grep -qE '[;&|`$()]' "$CONFIG_FILE"; then
            source "$CONFIG_FILE"
        else
            echo -e "${C_YELLOW}Warning: Config file contains invalid content. Using defaults.${C_RESET}"
            sleep 1
        fi
    fi
}

# --- Error Handling ---
function handle_error() {
    local command_name="$1"
    local error_message="$2"
    echo -e "${C_RED}Error during $command_name:${C_RESET}"
    echo -e "$error_message"
    echo ""
    echo -e "${C_YELLOW}Suggestions:${C_RESET}"
    
    # Context-specific suggestions
    if [[ "$command_name" == *"compile"* ]]; then
        echo "  - Check your code for syntax errors"
        echo "  - Ensure all required libraries are installed"
        echo "  - Verify the selected board (FQBN) is correct"
    elif [[ "$command_name" == *"upload"* ]]; then
        echo "  - Check the board is properly connected"
        echo "  - Verify the correct port is selected"
        echo "  - Try pressing the reset button on your board"
        echo "  - Close any other programs using the serial port"
    elif [[ "$command_name" == *"board"* ]]; then
        echo "  - Check USB cable connection"
        echo "  - Try a different USB port"
        echo "  - Install required drivers for your board"
    fi
}

function run_arduino_cli_command() {
    local command_args=("$@")
    local command_name="arduino-cli ${command_args[*]}"
    local output
    local error_output
    local exit_code

    output=$(arduino-cli "${command_args[@]}" 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        handle_error "$command_name" "$output"
        return 1 # Indicate failure
    else
        echo "$output" # Print successful output
        return 0 # Indicate success
    fi
}

# --- Version Comparison ---
function vercmp_portable() {
    local ver1=(${1//./ })
    local ver2=(${2//./ })
    local len=${#ver1[@]}
    (( ${#ver2[@]} > len )) && len=${#ver2[@]}

    for ((i=0; i<len; i++)); do
        local a=${ver1[i]:-0}
        local b=${ver2[i]:-0}
        ((10#$a > 10#$b)) && return 1
        ((10#$a < 10#$b)) && return 2
    done
    return 0
}

# --- Update Check ---
function check_for_update() {
    if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
        return # Skip check if jq or curl is not available
    fi

    local repo="abod8639/arduino-cli-manager"
    local response

    response=$(curl -s "https://api.github.com/repos/$repo/releases/latest")

    if echo "$response" | jq -e '.tag_name' > /dev/null; then
        LATEST_VERSION=$(echo "$response" | jq -r '.tag_name' | sed 's/v//') # Remove 'v' prefix if it exists
    fi
}

# --- Backup Function ---
function backup_project() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${project_name}_${timestamp}.tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${C_CYAN}Creating backup of '$project_name'...${C_RESET}"
    if tar -czf "$backup_path" -C "$(dirname "$project_path")" "$project_name" 2>/dev/null; then
        echo -e "${C_GREEN}Backup created: $backup_path${C_RESET}"
        
        # Keep only last 5 backups per project
        local backup_count=$(ls -t "$BACKUP_DIR/${project_name}"_*.tar.gz 2>/dev/null | wc -l)
        if [[ $backup_count -gt 5 ]]; then
            ls -t "$BACKUP_DIR/${project_name}"_*.tar.gz | tail -n +6 | xargs -r rm
            echo -e "${C_YELLOW}Cleaned up old backups (keeping last 5)${C_RESET}"
        fi
        log_operation "BACKUP" "SUCCESS" "$project_name"
        return 0
    else
        echo -e "${C_YELLOW}Warning: Could not create backup${C_RESET}"
        log_operation "BACKUP" "FAILED" "$project_name"
        return 1
    fi
}

# --- Logging Function ---
function log_operation() {
    local operation="$1"
    local status="$2"
    local details="${3:-}"
    
    mkdir -p "$LOG_DIR"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $operation - $status - $details" >> "$LOG_FILE"
    
    # Rotate log if it gets too large (> 1MB)
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
        if [[ $log_size -gt 1048576 ]]; then
            mv "$LOG_FILE" "$LOG_FILE.old"
            echo "[$timestamp] Log rotated" >> "$LOG_FILE"
        fi
    fi
}
