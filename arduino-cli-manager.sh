#!/bin/bash

# Arduino Project Manager - Interactive CLI Tool

# --- Configuration ---
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

# --- Dependency Check ---
function check_dependencies() {
    if ! command -v arduino-cli &> /dev/null; then
        echo -e "${C_RED}Error: 'arduino-cli' is not installed or not in your PATH.${C_RESET}"
        echo "Please install it to use this script."
        echo "Installation instructions can be found at:"
        echo -e "${C_YELLOW}https://arduino.github.io/arduino-cli/latest/installation/${C_RESET}"
        exit 1
    fi
}

# --- Config Functions ---
function save_config() {
    # Save current settings to the config file
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

function print_header() {
    clear
    echo ""
    # Cyan-colored ASCII Art Logo
    echo -e "${C_CYAN}"
    echo "  ██████╗  █████╗ ██████╗  ██╗   ██╗██╗███╗   ██╗ ██████╗ "
    echo "  ██╔══██╗██╔══██╗██╔══██╗ ██║   ██║██║████╗  ██║██╔═══██╗"
    echo "  ██████╔╝███████║██║  ██║ ██║   ██║██║██╔██╗ ██║██║   ██║"
    echo "  ██╔══██║██╔══██║██║  ██║ ██║   ██║██║██║╚██╗██║██║   ██║"
    echo "  ██████╔╝██║  ██║██████╔╝ ╚██████╔╝██║██║ ╚████║╚██████╔╝"
    echo "  ╚═════╝ ╚═╝  ╚═╝╚═════╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    echo -e "${C_RESET}"
    echo -e "${C_GREEN}"
    echo " ┌────────────────────────────────────────────────────────┐  "
    echo " │                 ARDUINO CLI MANAGER                    │  "
    echo " │                                                        │  "
    echo " │ Select board, serial, compile, upload & monitor easily │  "
    echo " └────────────────────────────────────────────────────────┘  "
    echo -e "${C_RESET}"
    echo "───────────────────────────────────────────────────────────"
    printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Board:"   "${FQBN:-$DEFAULT_FQBN}      "
    printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Port:"    "${PORT:-$DEFAULT_PORT}      "
    printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Baud:"    "${BAUD:-$DEFAULT_BAUD}      "
    printf " ${C_YELLOW}%-12s${C_RESET} %s\n" "Project:" "${PROJECT:-$DEFAULT_PROJECT}"
    echo "───────────────────────────────────────────────────────────"
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

function list_installed_boards() {
    print_header
    echo -e "${C_GREEN}==> Installed Boards:${C_RESET}"
    run_arduino_cli_command core list
    echo
    press_enter_to_continue
}

function list_all_supported_boards() {
    print_header
    echo -e "${C_GREEN}==> All Supported Boards (use this to find FQBNs):${C_RESET}"
    run_arduino_cli_command board listall | awk '{print $1}' | grep -v "FQBN"
    echo
    press_enter_to_continue
}

function _select_board_fzf() {
    print_header
    echo -e "${C_GREEN}==> Use interactive search. ${C_YELLOW}Enter${C_RESET} to select.${C_RESET}"
    local choice
    choice=$(run_arduino_cli_command board listall | sed '1d' | \
        fzf --reverse --prompt="Select a board: " \
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
        sleep 3
        _select_board_menu
    fi
}

function select_port() {
    print_header
    echo -e "${C_GREEN}==> Detecting connected boards...${C_RESET}"
    
    local board_list
    board_list=$(run_arduino_cli_command board list | awk 'NR>1')

    if [ -z "$board_list" ]; then
        echo -e "${C_RED}No connected boards found. Using default port: $DEFAULT_PORT${C_RESET}"
        PORT="$DEFAULT_PORT"
        sleep 2
        return
    fi

    # If multiple boards, let the user choose
    echo -e "${C_YELLOW}Multiple boards detected. Please select one:${C_RESET}"
    local choice
    choice=$( (echo "$board_list") | \
        fzf --reverse --header="Select a board/port" --prompt="Selection: "
    )

    if [[ -n "$choice" ]]; then
        PORT=$(echo "$choice" | awk '{print $1}')
        FQBN=$(echo "$choice" | awk '{print $(NF-1)}')
        echo -e "${C_GREEN}Selected port: ${C_YELLOW}${PORT}${C_RESET}"
        echo -e "${C_GREEN}Selected FQBN: ${C_YELLOW}${FQBN}${C_RESET}"
        sleep 2
    else
        echo -e "${C_RED}No selection made.${C_RESET}"
        sleep 1
    fi
}

function select_or_create_project() {
    print_header

    local search_dir="$SKETCH_DIR"

    if command -v fzf &> /dev/null; then
        while true; do
            print_header
            local find_cmd
            if command -v fd &> /dev/null; then
                find_cmd="fd . \"$search_dir\" --type d --max-depth 1"
            else
                find_cmd="find \"$search_dir\" -mindepth 1 -maxdepth 1 -type d"
            fi

            local projects
            projects=$(eval "$find_cmd" 2>/dev/null)

            local choice
            choice=$( (printf "--- CREATE NEW PROJECT in '%s' ---\n--- BROWSE other location ---\n%s" "$search_dir" "$projects") | \
                fzf --reverse --prompt="Select project in '$search_dir': " \
                    --header "Enter: select, Ctrl-D: delete project" \
                    --bind "ctrl-d:execute( \
                        if [[ {} != '---'* ]]; then \
                            read -p \"Delete project {/}? This is irreversible. [y/N] \" -n 1 -r; echo; \
                            if [[ \$REPLY =~ ^[Yy]$ ]]; then \
                                rm -rf '{}' && echo 'Project deleted. Re-enter menu to see changes.' || echo 'Failed to delete.'; \
                                sleep 2; \
                            fi; \
                        fi \
                    )"
            )

            if [[ -z "$choice" ]]; then
                return # User pressed Esc
            elif [[ "$choice" == "--- BROWSE other location ---" ]]; then
                read -e -rp "Enter new search directory: " new_dir
                if [[ -d "$new_dir" ]]; then
                    search_dir=$(realpath "$new_dir")
                else
                    echo -e "${C_RED}Directory not found: '$new_dir'${C_RESET}"
                    sleep 1
                fi
                continue # restart loop
            elif [[ "$choice" == "--- CREATE NEW PROJECT in '$search_dir' ---" ]]; then
                read -rp "Enter new sketch name: " name
                if [[ -n "$name" ]]; then
                    run_arduino_cli_command sketch new "$search_dir/$name"
                    PROJECT="$search_dir/$name"
                    break # exit loop
                fi
            else
                PROJECT="$choice"
                break # exit loop
            fi
        done
    else
        # Non-fzf version
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better project selection experience.${C_RESET}"
        sleep 2
        local menu_search_dir="$SKETCH_DIR"
        while true; do
            print_header
            echo -e "${C_GREEN}==> Project Directory: $menu_search_dir${C_RESET}"
            echo -e "    (1) Select an existing sketch"
            echo -e "    (2) Create a new sketch"
            echo -e "    (3) Change project directory"
            echo -e "    (b) Back to main menu"
            read -rp "Choose option [1/2/3/b]: " menu_choice

            case "$menu_choice" in
                "1"|"")
                    echo -e "${C_GREEN}==> Select a project from $menu_search_dir:${C_RESET}"
                    local current_dir
                    current_dir=$(pwd)
                    if ! cd "$menu_search_dir"; then
                        echo -e "${C_RED}Cannot access directory: $menu_search_dir${C_RESET}"
                        sleep 1
                        continue
                    fi

                    if ! compgen -G "*/" > /dev/null; then
                        echo -e "${C_YELLOW}No projects found in this directory.${C_RESET}"
                        cd "$current_dir"
                        sleep 1
                        continue
                    fi

                    select project_dir in */ "Cancel"; do
                        if [[ "$project_dir" == "Cancel" ]]; then
                            break
                        elif [[ -n "$project_dir" ]]; then
                            PROJECT="$menu_search_dir/${project_dir%/}"
                            cd "$current_dir"
                            return # project selected, exit function
                        else
                            echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
                        fi
                    done
                    cd "$current_dir"
                    ;;
                "2")
                    read -rp "Enter new sketch name: " name
                    if [[ -n "$name" ]]; then
                        run_arduino_cli_command sketch new "$menu_search_dir/$name"
                        PROJECT="$menu_search_dir/$name"
                        return # project created, exit function
                    fi
                    ;;
                "3")
                    read -e -rp "Enter new project directory: " new_dir
                    if [[ -d "$new_dir" ]]; then
                        menu_search_dir=$(realpath "$new_dir")
                    else
                        echo -e "${C_RED}Directory not found: '$new_dir'${C_RESET}"
                        sleep 1
                    fi
                    ;;
                "b")
                    return
                    ;;
                *)
                    echo -e "${C_RED}Invalid option.${C_RESET}"
                    sleep 1
                    ;;
            esac
        done
    fi
}

function compile_sketch() {
    print_header
    if [[ -z "$PROJECT" ]]; then
        echo -e "${C_RED}No project selected. Please select a project first.${C_RESET}"
        sleep 2
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

    if [[ -n "$PROJECT" && "$PROJECT" != "$DEFAULT_PROJECT" ]]; then
        echo -e "${C_GREEN}==> Current project is '${C_YELLOW}${PROJECT##*/}${C_GREEN}'.${C_RESET}"
        read -rp "Upload this project? [Y/n]: " choice
        if [[ -z "$choice" || "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${C_GREEN}==> Uploading sketch '${PROJECT##*/}'...${C_RESET}"
            run_arduino_cli_command upload --fqbn "${FQBN:-$DEFAULT_FQBN}" -p "${PORT:-$DEFAULT_PORT}" "$PROJECT" -v
            press_enter_to_continue
            return
        fi
    fi

    # If no project was selected, or user said no, show the fzf selection menu
    print_header
    echo -e "${C_GREEN}==> Select a project to upload:${C_RESET}"

    local find_cmd
    if command -v fd &> /dev/null; then
        find_cmd="fd . \"$SKETCH_DIR\" --type d --max-depth 1"
    else
        find_cmd="find \"$SKETCH_DIR\" -mindepth 1 -maxdepth 1 -type d"
    fi

    local project_to_upload
    project_to_upload=$(eval "$find_cmd" | \
        fzf --reverse --prompt="Select project to upload: "
    )

    if [[ -n "$project_to_upload" ]]; then
        echo -e "${C_GREEN}==> Uploading sketch '${project_to_upload##*/}'...${C_RESET}"
        run_arduino_cli_command upload --fqbn "${FQBN:-$DEFAULT_FQBN}" -p "${PORT:-$DEFAULT_PORT}" "$project_to_upload" -v
    fi

    press_enter_to_continue
}

function open_serial() {
    print_header

    read -rp "Use current baud rate (${BAUD:-$DEFAULT_BAUD})? [Y/n]: " use_current_baud
    if [[ -z "$use_current_baud" || "$use_current_baud" =~ ^[Yy]$ ]]; then
        :
    else
        local baud_rates=(
          "300"      
          "1200"     
          "2400"     
          "4800"     
          "9600"     
          "14400"    
          "19200"    
          "28800"    
          "38400"    
          "57600"    
          "74880"    
          "115200"   
          "128000"   
          "230400"   
          "250000"   
          "500000"   
          "1000000"  
          "2000000"  
          "Custom"   
        )
        
        echo -e "${C_GREEN}==> Select a baud rate (default: ${DEFAULT_BAUD}):${C_RESET}"

        if command -v fzf &>/dev/null; then
            BAUD=$(printf "%s\n" "${baud_rates[@]}" | fzf \
                --reverse \
                --cycle \
                --height=40% \
                --prompt="Baud Rate > " \
                --border \
                --color=prompt:green)
        else
            select choice in "${baud_rates[@]}" "Cancel"; do
                if [[ "$choice" == "Cancel" ]]; then
                    return
                fi
                BAUD="$choice"
                break
            done
        fi

        if [[ "$BAUD" == "Custom" ]]; then
            read -rp "Enter custom baud rate: " custom_baud
            BAUD="${custom_baud:-$DEFAULT_BAUD}"
            [[ -z "$custom_baud" ]] && echo -e "${C_YELLOW}No custom baud rate entered, using default: ${BAUD}${C_RESET}"
        elif [[ -z "$BAUD" ]]; then
            BAUD="$DEFAULT_BAUD"
            echo -e "${C_YELLOW}No baud rate selected, using default: ${BAUD}${C_RESET}"
        fi
    fi

    echo -e "${C_GREEN}==> Opening Serial Monitor on port ${PORT:-$DEFAULT_PORT} at ${BAUD} baud...${C_RESET}"
    echo -e "${C_YELLOW}(Press Ctrl+C to exit)${C_RESET}"
    sleep 1

    # Execute monitor directly for interactive session
    arduino-cli monitor -p "${PORT:-$DEFAULT_PORT}" --config "baudrate=${BAUD}"
    
    echo # Add a newline for better formatting after monitor exits
    press_enter_to_continue
}

function install_core() {
    print_header
    local core_name=""

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
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 3

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
        echo -e " ${C_BLUE}1.${C_RESET} Select/Create Project          ${C_BLUE}6.${C_RESET} List Installed Cores"
        echo -e " ${C_BLUE}2.${C_RESET} Select Board (FQBN)            ${C_BLUE}7.${C_RESET} List All Boards"
        echo -e " ${C_BLUE}3.${C_RESET} Select Port                    ${C_BLUE}8.${C_RESET} Install a Core"
        echo -e " ${C_BLUE}4.${C_RESET} Compile Current Project        ${C_BLUE}9.${C_RESET} Open Serial Monitor"
        echo -e " ${C_BLUE}5.${C_RESET} Upload a Project"   
        echo
        echo -e " ${C_RED}0. Exit${C_RESET}"
        echo "───────────────────────────────────────────────────────────"
        read -rp "Choose option: " option

        case $option in
        1) select_or_create_project ;;
        2) select_board ;;
        3) select_port ;;
        4) compile_sketch ;;
        5) upload_sketch ;;
        6) list_installed_boards ;;
        7) list_all_supported_boards ;;
        8) install_core ;;
        9) open_serial ;;
        0) clear; echo "Goodbye!"; break ;;
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

main_menu