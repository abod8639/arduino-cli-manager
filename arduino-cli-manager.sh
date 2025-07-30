#!/bin/bash

# Arduino Project Manager - Interactive CLI Tool
#
# Copyright (c) 2025 abod8639
#
# This script is licensed under the MIT License.
# See the LICENSE file for details.

# --- Configuration ---
VERSION="1.0.8" # Script version
DEFAULT_FQBN="esp32:esp32:esp32"
DEFAULT_PORT="/dev/ttyACM1"
DEFAULT_BAUD="115200"
DEFAULT_PROJECT="Not Selected"
SKETCH_DIR="$HOME/Arduino"
CONFIG_FILE="$HOME/.arduino-cli-manager.conf"

 
# --- Colors ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'

# --- State Variables ---
FQBN=""
PORT=""
BAUD=""
PROJECT=""
LATEST_VERSION=""

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
        source "$CONFIG_FILE"
    fi
}

# --- UI Functions ---

function print_logo() {
     echo ""
     echo -e "${C_CYAN}  ██████╗  █████╗ ██████╗  ██╗   ██╗██╗███╗   ██╗ ██████╗ "
                 echo "  ██╔══██╗██╔══██╗██╔══██╗ ██║   ██║██║████╗  ██║██╔═══██╗"
                 echo "  ██████╔╝███████║██║  ██║ ██║   ██║██║██╔██╗ ██║██║   ██║"
                 echo "  ██╔══██║██╔══██║██║  ██║ ██║   ██║██║██║╚██╗██║██║   ██║"
                 echo "  ██████╔╝██║  ██║██████╔╝ ╚██████╔╝██║██║ ╚████║╚██████╔╝"
              echo -e "  ╚═════╝ ╚═╝  ╚═╝╚═════╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ${C_RESET}"
}

function print_header() {
    clear
                                              print_logo
    echo -e "${C_GREEN} ┌────────────────────────────────────────────────────────┐"
                 echo " │                 ARDUINO CLI MANAGER                    │"
                 echo " │                                                        │"
                 echo " │ Select board, serial, compile, upload & monitor easily │"
              echo -e " └────────────────────────────────────────────────────────┘${C_RESET}"
                                          get_version_line
                 echo "────────────────────────────────────────────────────────────"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Project:" "${PROJECT:-$DEFAULT_PROJECT}"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Board:"   "${FQBN:-   $DEFAULT_FQBN}"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Port:"    "${PORT:-   $DEFAULT_PORT}"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Baud:"    "${BAUD:-   $DEFAULT_BAUD}"
                 echo "────────────────────────────────────────────────────────────"
}


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

function get_version_line() {
    local current="${VERSION#v}"
    local latest="${LATEST_VERSION#v}"

    if [[ -n "$LATEST_VERSION" ]]; then
        vercmp_portable "$latest" "$current"
        local result=$?
        if [[ $result -eq 1 ]]; then
            local update_msg="Update available: v$VERSION → v$LATEST_VERSION"
            printf " ${C_YELLOW}%*s${C_RESET}${C_GREEN}%*s \n" $(( (59 + ${#update_msg}) / 2 )) "$update_msg" $(( (59 - ${#update_msg}) / 2 )) ""
            return
        fi
    fi

    local version_msg="v$VERSION"
    printf "${C_GREEN} %*s%*s \n${C_RESET}" $(( (59 + ${#version_msg}) / 2 )) "$version_msg" $(( (59 - ${#version_msg}) / 2 )) ""
}


function press_enter_to_continue() {
    read -p "Press Enter to continue..."
}

function handle_error() {
    local command_name="$1"
    local error_message="$2"
    echo -e "${C_RED}Error during $command_name: ${error_message}${C_RESET}"
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

# --- Core Functions ---

function list_all_supported_boards() {
    print_header
    echo -e "${C_GREEN}==> All Supported Boards (use this to find FQBNs):${C_RESET}"
    run_arduino_cli_command board listall 
    echo
    press_enter_to_continue
}

function _select_board_fzf() {
    print_header
    echo -e "${C_GREEN}==> Use interactive search. ${C_YELLOW}Enter${C_RESET} to select.${C_RESET}"
    local choice
    choice=$(run_arduino_cli_command board listall | sed '1d' | \
        fzf --height=50% --reverse --prompt="Select a board: " \
            --header "Enter to select." )
    
    if [[ -n "$choice" ]]; then
        local selected_fqbn
        selected_fqbn=$(echo "$choice" | awk '{for (i=1; i<=NF; i++) {if ($i ~ /.*:.*:.*/) {print $i; break}}}')
        FQBN="$selected_fqbn"
        echo
        echo -e "${C_GREEN}Selected board: ${C_YELLOW}$FQBN${C_RESET}"
        press_enter_to_continue
    fi
}

function _select_board_menu() {
    print_header
    local all_boards
    mapfile -t all_boards < <(run_arduino_cli_command board listall | sed '1d') # Pre-load all boards, remove header

    while true; do
        print_header
        echo -e "${C_GREEN}==> Enter a search term to filter boards.${C_RESET}"
        read -rp "Search (or press Enter for all, 'q' to quit): " search_term

        if [[ "$search_term" == "q" ]]; then
            return
        fi

        local filtered_boards=()
        for board in "${all_boards[@]}"; do
            if [[ -z "$search_term" || "$board" =~ .*$search_term.* ]]; then
                filtered_boards+=("$board")
            fi
        done

        if [ ${#filtered_boards[@]} -eq 0 ]; then
            echo -e "${C_RED}No boards found matching '$search_term'.${C_RESET}"
            sleep 1
            continue # Restart the loop
        fi

        echo
        echo -e "${C_GREEN}==> Select a board:${C_RESET}"
        select choice in "${filtered_boards[@]}" "New Search" "Cancel"; do
            if [[ "$choice" == "New Search" ]]; then
                break # Exit select, re-enter while loop
            elif [[ "$choice" == "Cancel" ]]; then
                return # Exit function
            elif [[ -n "$choice" ]]; then
                # Robustly extract FQBN
                local selected_fqbn
                selected_fqbn=$(echo "$choice" | awk '{for (i=1; i<=NF; i++) {if ($i ~ /.*:.*:.*/) {print $i; break}}}')
                FQBN="$selected_fqbn"
                echo
                echo -e "${C_GREEN}Selected board: ${C_YELLOW}$FQBN${C_RESET}"
                press_enter_to_continue
                return # Exit function
            else
                echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
            fi
        done
    done
}

function select_board() {
    print_header
    # Check if fzf is installed for a better experience
    if command -v fzf &> /dev/null; then
        _select_board_fzf
    else
        print_header
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 1
        _select_board_menu
    fi
}

function select_port() {
    print_header
    echo -e "${C_GREEN}==> Detecting connected boards...${C_RESET}"
    
    local board_list
    # Use run_arduino_cli_command for better error handling
    if ! board_list=$(run_arduino_cli_command board list | awk 'NR>1'); then
        echo -e "${C_RED}Failed to detect boards. Please check your connections.${C_RESET}"
        press_enter_to_continue
        return 1
    fi

    if [ -z "$board_list" ]; then
        echo -e "${C_RED}No connected boards found.${C_RESET}"
        local use_default
        read -rp "$(echo -e "Use default port ${C_YELLOW}$DEFAULT_PORT${C_RESET}? [Y/n]: ")" use_default
        if [[ -z "$use_default" || "$use_default" =~ ^[Yy]$ ]]; then
            PORT="$DEFAULT_PORT"
            echo -e "${C_GREEN}Using default port: ${C_YELLOW}$DEFAULT_PORT${C_RESET}"
            save_config # Save the port selection to config
            sleep 1
            return 0
        fi
        return 1
    fi

    # Format board information for display
    local formatted_list=""
    while IFS= read -r line; do
        local port=$(echo "$line" | awk '{print $1}')
        local board_name=$(echo "$line" | awk -F'[()]' '{print $2}')
        local fqbn=$(echo "$line" | awk '{print $(NF-1)}')
        formatted_list+="Port: ${port} | Board: ${board_name} | FQBN: ${fqbn}\n"
    done <<< "$board_list"

    local choice
    if command -v fzf &> /dev/null; then
        # Use fzf if available for better UX
        echo -e "${C_GREEN}==> Select a board:${C_RESET}"
        choice=$( (echo -e "$formatted_list") | \
            fzf --height=50% \
                --reverse \
                --header="Use arrows to move, Enter to select" \
                --prompt="Select board > " \
                --ansi
        )
    else
        # Fallback to simple select menu
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better selection experience.${C_RESET}"
        echo -e "${C_GREEN}==> Available boards:${C_RESET}"
        echo -e "$formatted_list"
        
        local -a options
        while IFS= read -r line; do
            options+=("$line")
        done <<< "$board_list"
        
        select opt in "${options[@]}" "Cancel"; do
            if [[ "$opt" == "Cancel" ]]; then
                return 1
            elif [[ -n "$opt" ]]; then
                choice="Port: $(echo "$opt" | awk '{print $1}') | Board: $(echo "$opt" | awk -F'[()]' '{print $2}') | FQBN: $(echo "$opt" | awk '{print $(NF-1)}')"
                break
            fi
        done
    fi

    if [[ -n "$choice" ]]; then
        # Extract port and FQBN from the formatted choice
        PORT=$(echo "$choice" | sed -n 's/.*Port: \([^ ]*\).*/\1/p')
        FQBN=$(echo "$choice" | sed -n 's/.*FQBN: \([^ ]*\).*/\1/p')
        
        echo -e "\n${C_GREEN}Selected:${C_RESET}"
        echo -e "${C_CYAN}Port:${C_RESET} ${C_YELLOW}${PORT}${C_RESET}"
        echo -e "${C_CYAN}FQBN:${C_RESET} ${C_YELLOW}${FQBN}${C_RESET}"
        
        save_config # Save the port selection to config
        sleep 1
        return 0
    else
        echo -e "${C_RED}No selection made.${C_RESET}"
        sleep 1
        return 1
    fi
}

function select_or_create_project() {
    print_header

    if command -v fzf &> /dev/null; then 

    

        local find_cmd
        if command -v fd &> /dev/null; then
            find_cmd="fd . \"$SKETCH_DIR\" --type d --max-depth 1"
        else
            find_cmd="find \"$SKETCH_DIR\" -mindepth 1 -maxdepth 1 -type d"
        fi

        local projects
        projects=$(eval "$find_cmd")

        local choice
        choice=$( (echo "--- CREATE NEW PROJECT ---"; echo "$projects") | \
            fzf --reverse --prompt="Select or create a project: " \
            --height=50%\
                --header "Enter to select."
        )

        if [[ -z "$choice" ]]; then
            return # User pressed Esc
        elif [[ "$choice" == "--- CREATE NEW PROJECT ---" ]]; then
            read -rp "Enter new sketch name: " name
            if [[ -n "$name" ]]; then
                run_arduino_cli_command sketch new "$SKETCH_DIR/$name"
                PROJECT="$SKETCH_DIR/$name"
            fi
        else
            PROJECT="$choice"
        fi
    else
        # Fallback to the original menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better project selection experience.${C_RESET}"
        sleep 1
        print_header
        echo -e "${C_GREEN}==> (1) Select an existing sketch? \n==> (2) Create a new sketch?${C_RESET}"
        read -rp "[1/2]: " menu_choice
        if [[ "$menu_choice" == "2" ]]; then
            read -rp "Enter new sketch name: " name
            if [[ -n "$name" ]]; then
                run_arduino_cli_command sketch new "$SKETCH_DIR/$name"
                PROJECT="$SKETCH_DIR/$name"
            fi
        else
            echo -e "${C_GREEN}==> Select a project from $SKETCH_DIR:${C_RESET}"
            local current_dir
            current_dir=$(pwd)
            cd "$SKETCH_DIR" || return

            select project_dir in */ "Cancel"; do
                if [[ "$project_dir" == "Cancel" ]]; then
                    break
                elif [[ -n "$project_dir" ]]; then
                    PROJECT="$SKETCH_DIR/${project_dir%/}"
                    break
                else
                    echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
                fi
            done
            cd "$current_dir"
        fi
    fi
}


function compile_sketch() {
    print_header
    if [[ -z "$PROJECT" ]]; then
        echo -e "${C_RED}No project selected. Please select a project first.${C_RESET}"
        sleep 1
        return
    fi
    echo -e "${C_GREEN}==> Compiling sketch '${PROJECT##*/}'...${C_RESET}"
    if ! arduino-cli compile --fqbn "${FQBN:-$DEFAULT_FQBN}" "$PROJECT"; then
        echo -e "${C_RED}Error: Compilation failed for '${PROJECT##*/}'. Please check the output above for details.${C_RESET}"
        press_enter_to_continue 
        return 
    fi
    echo -e "${C_GREEN}Sketch '${PROJECT##*/}' compiled successfully.${C_RESET}"
    press_enter_to_continue
}

function upload_sketch() {
    print_header

    # 1. Select project if not already selected
    local project_to_upload="$PROJECT"
    if [[ -z "$project_to_upload" || "$project_to_upload" == "$DEFAULT_PROJECT" ]]; then
        echo -e "${C_YELLOW}No project is currently selected.${C_RESET}"
        select_or_create_project
        project_to_upload="$PROJECT" # Update after selection
        if [[ -z "$project_to_upload" || "$project_to_upload" == "$DEFAULT_PROJECT" ]]; then
            return # User cancelled selection
        fi
    fi

    local upload_port
    local upload_fqbn

    # 2. Check if we're doing OTA upload
    if [[ "$PORT" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # For OTA upload, use the currently selected FQBN and PORT
        upload_port="$PORT"
        upload_fqbn="${FQBN:-$DEFAULT_FQBN}"
        echo -e "${C_GREEN}Using IP address for OTA upload: ${C_YELLOW}${upload_port}${C_RESET}"
        echo -e "${C_GREEN}Using FQBN: ${C_YELLOW}${upload_fqbn}${C_RESET}"

        # Compile first for OTA, directing output to a 'build' folder
        echo -e "${C_GREEN}==> Compiling sketch '${project_to_upload##*/}' for OTA...${C_RESET}"
        if ! arduino-cli compile --fqbn "$upload_fqbn" --output-dir "$project_to_upload/build" "$project_to_upload"; then
            echo -e "${C_RED}Error: Compilation failed. Please check the output above.${C_RESET}"
            press_enter_to_continue
            return
        fi

        # Perform OTA upload using the compiled artifacts
        echo -e "${C_GREEN}==> Performing OTA upload to ${C_YELLOW}${upload_port}${C_RESET}...${C_RESET}"
        if ! arduino-cli upload --fqbn "$upload_fqbn" -p "$upload_port" "$project_to_upload" -v --input-dir "$project_to_upload/build"; then
            echo -e "${C_RED}Error: OTA upload failed. Please check the output above.${C_RESET}"
            echo -e "${C_YELLOW}Make sure the device is powered on and connected to the network.${C_RESET}"
            echo -e "${C_YELLOW}Also verify that OTA is enabled in your sketch.${C_RESET}"
            press_enter_to_continue
            return
        fi

    else
        # Regular USB upload - detect and select port
        echo -e "${C_GREEN}==> Detecting connected boards for upload...${C_RESET}"
        local board_list
        board_list=$(run_arduino_cli_command board list | awk 'NR>1')

        if [ -z "$board_list" ]; then
            echo -e "${C_RED}No connected boards found. Cannot upload.${C_RESET}"
            press_enter_to_continue
            return
        fi
    
        if [ "$(echo "$board_list" | wc -l)" -eq 1 ]; then
            upload_port=$(echo "$board_list" | awk '{print $1}')
            upload_fqbn=$(echo "$board_list" | awk '{print $(NF-1)}')
            echo -e "${C_GREEN}Auto-selected port: ${C_YELLOW}${upload_port}${C_RESET}"
        else
            echo -e "${C_YELLOW}Multiple boards detected. Please select one for upload:${C_RESET}"
            
            local formatted_list=""
            while IFS= read -r line; do
                local port=$(echo "$line" | awk '{print $1}')
                local board_name=$(echo "$line" | awk -F'[()]' '{print $2}')
                local fqbn=$(echo "$line" | awk '{print $(NF-1)}')
                formatted_list+="Port: ${port} | Board: ${board_name} | FQBN: ${fqbn}\n"
            done <<< "$board_list"

            local choice
            if command -v fzf &> /dev/null; then
                choice=$( (echo -e "$formatted_list") | \
                    fzf --height=50% --reverse --header="Use arrows to move, Enter to select" \
                        --prompt="Select board > " --ansi )
            else
                echo -e "${C_YELLOW}Tip: Install 'fzf' for a better selection experience.${C_RESET}"
                echo -e "${C_GREEN}==> Available boards:${C_RESET}"
                echo -e "$formatted_list"
                local -a options
                while IFS= read -r line; do options+=("$line"); done <<< "$board_list"
                select opt in "${options[@]}" "Cancel"; do
                    if [[ "$opt" == "Cancel" ]]; then return 1;
                    elif [[ -n "$opt" ]]; then
                        choice="Port: $(echo "$opt" | awk '{print $1}') | Board: $(echo "$opt" | awk -F'[()]' '{print $2}') | FQBN: $(echo "$opt" | awk '{print $(NF-1)}')"
                        break
                    fi
                done
            fi

            if [[ -n "$choice" ]]; then
                upload_port=$(echo "$choice" | sed -n 's/.*Port: \([^ ]*\).*/\1/p')
                upload_fqbn=$(echo "$choice" | sed -n 's/.*FQBN: \([^ ]*\).*/\1/p')
            else
                echo -e "${C_RED}No selection made. Aborting upload.${C_RESET}"
                press_enter_to_continue
                return
            fi
        fi
        
        # For regular upload, compile and upload in one step
        echo -e "${C_GREEN}==> Compiling and uploading to port ${C_YELLOW}${upload_port}${C_RESET}...${C_RESET}"
        if ! arduino-cli upload --fqbn "$upload_fqbn" -p "$upload_port" "$project_to_upload" -v; then
            echo -e "${C_RED}Error: Upload failed. Please check the output above.${C_RESET}"
            press_enter_to_continue
            return
        fi
    fi

    # Update global state with the used values
    PORT="$upload_port"
    FQBN="$upload_fqbn"
    save_config  # Save the successful configuration
    
    echo -e "${C_GREEN}Sketch '${project_to_upload##*/}' uploaded successfully!${C_RESET}"
    

}

function open_serial() {
    print_header
    echo -e "${C_GREEN}==> Opening Serial Monitor...${C_RESET}"

    # 1. Detect and select port
    local board_list
    board_list=$(run_arduino_cli_command board list | awk 'NR>1')

    if [ -z "$board_list" ]; then
        echo -e "${C_RED}No connected boards found. Cannot open serial monitor.${C_RESET}"
        press_enter_to_continue
        return
    fi

    local selected_port=""
    
    # If only one board is connected, use it automatically
    if [ "$(echo "$board_list" | wc -l)" -eq 1 ]; then
        selected_port=$(echo "$board_list" | awk '{print $1}')
        echo -e "${C_GREEN}Auto-selected port: ${C_YELLOW}${selected_port}${C_RESET}"
        PORT="$selected_port" # Update global state
    else
        # If multiple boards, let the user choose
        echo -e "${C_YELLOW}Multiple boards detected. Please select one:${C_RESET}"
        local choice
        choice=$( (echo "$board_list") | \
            fzf --reverse --header="Select a board/port to monitor" --prompt="Selection: "
        )

        if [[ -n "$choice" ]]; then
            selected_port=$(echo "$choice" | awk '{print $1}')
            PORT="$selected_port" # Update global state
        else
            echo -e "${C_RED}No selection made. Aborting.${C_RESET}"
            press_enter_to_continue
            return
        fi
    fi

    # 2. Select baud rate
    local current_baud="${BAUD:-$DEFAULT_BAUD}"
    local use_current_prompt="Current baud rate (${C_YELLOW}$current_baud${C_RESET})؟ [Y/n]: "
    read -rp "$(echo -e "$use_current_prompt")" use_current
    echo

    if [[ "$use_current" =~ ^[Nn]$ ]]; then
        echo -e "${C_GREEN}==> Select a baud rate (current: ${C_YELLOW}$current_baud${C_GREEN})${C_RESET}"

        local baud_rates=(
        "9600"
        "19200"
        "38400"
        "57600"
        "74880"
        "115200"
        "230400"
        "250000"
        "500000"
        "1000000"
        "Custom"
        )

        local selected_baud

        if command -v fzf &>/dev/null; then
            selected_baud=$(printf "%s\n" "${baud_rates[@]}" | fzf \
                --reverse \
                --cycle \
                --height=50% \
                --prompt="Current baud rate " \
                --header="Select a baud rate" \
                --border \
                --color=prompt:green \
                --query=" ")
        else
            # For the select menu, create a new array with the current value marked.
            local menu_options=()
            for rate in "${baud_rates[@]}"; do
                if [[ "$rate" == "$current_baud" ]]; then
                    menu_options+=("$rate <== current")
                else
                    menu_options+=("$rate")
                fi
            done
            menu_options+=("Cancel")

            select choice in "${menu_options[@]}"; do
                if [[ "$choice" == "Cancel" ]]; then
                    return
                fi
                # Remove the marker before setting the baud rate
                selected_baud=${choice% *<==*}
                break
            done
        fi

        if [[ -z "$selected_baud" ]]; then
            echo -e "${C_YELLOW}لم يتم اختيار معدل باود، سيتم استخدام الحالي: $current_baud${C_RESET}"
            # BAUD remains unchanged
        elif [[ "$selected_baud" == "Custom" ]]; then
            read -rp "ادخل معدل باود مخصص: " custom_baud
            if [[ -n "$custom_baud" ]]; then
                BAUD="$custom_baud"
            else
                echo -e "${C_YELLOW}لم يتم إدخال معدل باود مخصص، سيتم استخدام الحالي: $current_baud${C_RESET}"
            fi
        else
            BAUD="$selected_baud"
        fi
    fi

    # 3. Open monitor
    echo -e "${C_GREEN}==> Opening Serial Monitor on port ${PORT} at ${BAUD} baud...${C_RESET}"
    echo -e "${C_YELLOW}(Press Ctrl+C to exit)${C_RESET}"
    sleep 1

    # Execute monitor directly for interactive session
    arduino-cli monitor -p "${PORT}" --config "baudrate=${BAUD}"
    
    echo # Add a newline for better formatting after monitor exits
    press_enter_to_continue
}

function edit_project_nvim() {
    print_header
    if [[ -z "$PROJECT" || "$PROJECT" == "$DEFAULT_PROJECT" ]]; then
        echo -e "${C_RED}No project selected. Please select a project first.${C_RESET}"
        select_or_create_project
        # If user cancelled, PROJECT is still empty. Return to menu.
        if [[ -z "$PROJECT" || "$PROJECT" == "$DEFAULT_PROJECT" ]]; then
            return
        fi
    fi

    if ! command -v nvim &> /dev/null; then
        echo -e "${C_RED}Error: 'nvim' is not installed or not in your PATH.${C_RESET}"
        echo "Please install it to use this feature."
        press_enter_to_continue
        return
    fi

    local project_name
    project_name=$(basename "$PROJECT")

    echo -e "${C_GREEN}==> Opening project '${project_name}' in nvim...${C_RESET}"
    # sleep 1
    
    # Change to the project directory and open the main .ino file
    (
        cd "$PROJECT" && nvim "${project_name}.ino"
    )
    
    echo # Add a newline for better formatting after nvim exits
    # press_enter_to_continue
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

function list_installed_cores() {
    print_header
    echo -e "${C_GREEN}==> Installed Cores:${C_RESET}"
    run_arduino_cli_command core list
    echo
    press_enter_to_continue
}

function update_script() {
    print_header
    if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
        echo -e "${C_GREEN}==> Update Available! ${C_RESET}"
        echo -e "A new version (${C_YELLOW}v$LATEST_VERSION${C_RESET}) of the script is available."
        echo -e "Your current version is ${C_YELLOW}v$VERSION${C_RESET}."
        echo
        read -rp "Do you want to update now? [Y/n]: " update_choice
        if [[ -z "$update_choice" || "$update_choice" =~ ^[Yy]$ ]]; then
            echo -e "${C_GREEN}==> Updating script...${C_RESET}"
            local repo="abod8639/arduino-cli-manager"
            # Use $0 to refer to the script itself, making it self-updating
            if curl -sL "https://raw.githubusercontent.com/$repo/main/arduino-cli-manager.sh" -o "$0" && chmod +x "$0"; then
                echo -e "${C_GREEN}Update successful! Please restart the script to use the new version.${C_RESET}"
                exit 0
            else
                echo -e "${C_RED}Error: Update failed. Please try again later or update manually.${C_RESET}"
                press_enter_to_continue
            fi
        else
            echo "Update skipped."
            press_enter_to_continue
        fi
    else
        echo -e "${C_GREEN}You are already on the latest version (v$VERSION).${C_RESET}"
        press_enter_to_continue
    fi
}


function install_core() {
    print_header
    local core_name=""

    # Check if fzf is installed for a better experience
    if command -v fzf &> /dev/null; then
        echo -e "${C_GREEN}==> Use interactive search to find and select cores.${C_RESET}"
        echo -e "${C_YELLOW}Use TAB to multi-select. Enter to install.${C_RESET}"

        local installed_cores
        installed_cores=$(run_arduino_cli_command core list | awk 'NR>1 {print $1}')

        local choices
        choices=$(run_arduino_cli_command core search --all | sed '1d' | \
            fzf --reverse --prompt="Select core(s) to install: " -m \
                --header "TAB to multi-select, Enter to install."
        )

        if [[ -n "$choices" ]]; then
            echo "$choices" | while read -r choice; do
                core_name=$(echo "$choice" | awk '{print $1}')
                if [[ -n "$core_name" ]]; then
                    echo -e "${C_GREEN}==> Installing '$core_name'...${C_RESET}"
                    if ! arduino-cli core install "$core_name"; then
                        echo -e "${C_RED}Error: Core installation failed for '$core_name'.${C_RESET}"
                    else
                        echo -e "${C_GREEN}Core '$core_name' installed successfully.${C_RESET}"
                    fi
                fi
            done
        else
            echo -e "${C_RED}No core selected.${C_RESET}"
            sleep 1
        fi
        press_enter_to_continue
        return
    else
        # Fallback to menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 1

        echo -e "${C_GREEN}==> Available Cores:${C_RESET}"
        mapfile -t all_cores < <(run_arduino_cli_command core search --all | sed '1d')

        select choice in "${all_cores[@]}" "Cancel"; do
            if [[ "$choice" == "Cancel" ]]; then
                break
            elif [[ -n "$choice" ]]; then
                core_name=$(echo "$choice" | awk '{print $1}')
                break
            else
                echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
            fi
        done
    fi

    if [[ -n "$core_name" ]]; then
        echo -e "${C_GREEN}==> Installing '$core_name'...${C_RESET}"
        # Execute directly to show live progress
        if ! arduino-cli core install "$core_name"; then
            echo -e "${C_RED}Error: Core installation failed for '$core_name'. Please check the output above for details.${C_RESET}"
            press_enter_to_continue # Add this here so the user can read the error before the screen clears
            return # Exit the function on failure
        fi
        echo -e "${C_GREEN}Core '$core_name' installed successfully.${C_RESET}"
    else
        echo -e "${C_RED}No core selected or entered.${C_RESET}"
        sleep 1
    fi
    press_enter_to_continue
}

function main_menu() {
    while true; do
        print_header
        echo -e " ${C_YELLOW}1 (S) S${C_RESET}elect/Create Project    "
        echo -e " ${C_YELLOW}2 (B)${C_RESET} Select ${C_YELLOW}B${C_RESET}oard (FQBN)      "
        echo -e " ${C_YELLOW}3 (P)${C_RESET} Select ${C_YELLOW}P${C_RESET}ort              "
        echo -e " ${C_YELLOW}5 (U) U${C_RESET}pload Project           "
        echo -e " ${C_YELLOW}4 (C) C${C_RESET}ompile Project          "
        echo -e " ${C_YELLOW}6 (L) L${C_RESET}ist Installed Cores     "
        echo -e " ${C_YELLOW}7 (A)${C_RESET} List ${C_YELLOW}A${C_RESET}ll Supported Boards"
        echo -e " ${C_YELLOW}8 (I) I${C_RESET}nstall Core             " 
        echo -e " ${C_YELLOW}9 (M)${C_RESET} Open Serial ${C_YELLOW}M${C_RESET}onitor      "
        echo -e " ${C_YELLOW}0 (E) E${C_RESET}dit Project (nvim)      "
        echo "────────────────────────────────────────────────────────────"
        
        local update_prompt=""
        if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
            update_prompt="(${C_YELLOW}V${C_RESET}) Update to v$LATEST_VERSION"
        fi
        
        echo -e " ${update_prompt}${update_prompt:+, }(${C_RED}Q${C_RESET}) Quit"
        echo "────────────────────────────────────────────────────────────"

        read -rp "Enter your choice: " -n 1 option
        echo

        case $option in
            [1sS]) select_or_create_project ;;
            [2bB]) select_board ;;
            [3pP]) select_port ;;
            [4cC]) compile_sketch ;;
            [5uU]) upload_sketch ;;
            [6lL]) list_installed_cores ;;
            [7aA]) list_all_supported_boards ;;
            [8iI]) install_core ;;
            [9mM]) open_serial ;;
            [0eE]) edit_project_nvim ;;

            [vV]) 
                if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
                    update_script
                else
                    echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1
                fi
                ;;

            [qQ]) clear
            
                print_logo
  echo " Goodbye Genius! V$VERSION"
  break
  ;;
            *) echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1 ;;
        esac
    done
}


# --- Initialization ---
check_dependencies
mkdir -p "$SKETCH_DIR"

# Load config and save on exit
load_config
trap save_config EXIT

check_for_update
main_menu
