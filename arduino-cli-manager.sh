#!/bin/bash

# Arduino Project Manager - Interactive CLI Tool

# --- Configuration ---
DEFAULT_FQBN="esp32:esp32:esp32"
DEFAULT_PORT="/dev/ttyACM1"
DEFAULT_PROJECT="Not Selected"
SKETCH_DIR="$HOME/Arduino"

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
PROJECT=""

# --- UI Functions ---

function print_header() {
    clear
    echo ""
    echo -e "${C_CYAN}"
    echo "  █████╗ ██████╗ ██████╗ ██╗   ██╗██╗███╗   ██╗ ██████╗ "
    echo " ██╔══██╗██╔══██╗██╔══██╗██║   ██║██║████╗  ██║██╔════╝ "
    echo " ███████║██████╔╝██████╔╝██║   ██║██║██╔██╗ ██║██║  ███╗"
    echo " ██╔══██║██╔═══╝ ██╔═══╝ ██║   ██║██║██║╚██╗██║██║   ██║"
    echo " ██║  ██║██║     ██║     ╚██████╔╝██║██║ ╚████║╚██████╔╝"
    echo " ╚═╝  ╚═╝╚═╝     ╚═╝      ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    echo -e "${C_CYAN}"
    echo -e "${C_GREEN}"
    echo "     ┌───────────────────────────────────────────────┐"
    echo "     │               ARDUINO MANAGER                 │"
    echo "     │ select board, serial, compile, upload & more  │"
    echo "     └───────────────────────────────────────────────┘"
    echo -e "${C_GREEN}"
    echo "----------------------------------------------------------"
    echo -e " ${C_YELLOW}Board:${C_RESET}    ${FQBN:-$DEFAULT_FQBN} "
    echo -e " ${C_YELLOW}Port:${C_RESET}     ${PORT:-$DEFAULT_PORT}"
    echo -e " ${C_YELLOW}Project:${C_RESET}  ${PROJECT##*/:-$DEFAULT_PROJECT}"
    echo "----------------------------------------------------------"
}

function press_enter_to_continue() {
    read -p "Press Enter to continue..."
}

# --- Core Functions ---

function list_installed_boards() {
    print_header
    echo -e "${C_GREEN}==> Installed Boards:${C_RESET}"
    arduino-cli core list
    echo
    press_enter_to_continue
}

function list_all_supported_boards() {
    print_header
    echo -e "${C_GREEN}==> All Supported Boards (use this to find FQBNs):${C_RESET}"
    arduino-cli board listall | awk '{print $1}' | grep -v "FQBN"
    echo
    press_enter_to_continue
}

# --- Helper function for fzf-based board selection ---
function _select_board_fzf() {
    print_header
    echo -e "${C_GREEN}==> Use the interactive search to find and select a board.${C_RESET}"
    local choice
    # Use fzf for an interactive filter
    choice=$(arduino-cli board listall | sed '1d' | fzf --height 40% --reverse --prompt="Select a board: ")
    
    if [[ -n "$choice" ]]; then
        # Robustly extract FQBN by looking for the pattern vendor:arch:board
        local selected_fqbn
        selected_fqbn=$(echo "$choice" | awk '{for (i=1; i<=NF; i++) {if ($i ~ /.*:.*:.*/) {print $i; break}}}')
        FQBN="$selected_fqbn"
        echo
        echo -e "${C_GREEN}Selected board: ${C_YELLOW}$FQBN${C_RESET}"
        press_enter_to_continue
    fi
}

# --- Helper function for menu-based board selection ---
function _select_board_menu() {
    local all_boards
    mapfile -t all_boards < <(arduino-cli board listall | sed '1d') # Pre-load all boards, remove header

    while true; do
        print_header
        echo -e "${C_GREEN}==> Enter a search term to filter boards.${C_RESET}"
        read -rp "Search (or press Enter for all, 'q' to quit): " search_term

        if [[ "$search_term" == "q" ]]; then
            return
        fi

        # Filter the pre-loaded list
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

# --- Main function to select a board ---
function select_board() {
    # Check if fzf is installed for a better experience
    if command -v fzf &> /dev/null; then
        _select_board_fzf
    else
        # Inform the user about fzf and fall back to the menu
        print_header
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 3
        _select_board_menu
    fi
}

function select_port() {
    print_header
    echo -e "${C_GREEN}==> Select a port:${C_RESET}"
    mapfile -t ports < <(arduino-cli board list | awk 'NR>1')

    if [ ${#ports[@]} -eq 0 ]; then
        echo -e "${C_RED}No connected boards found. Using default port: $DEFAULT_PORT${C_RESET}"
        PORT="$DEFAULT_PORT"
        sleep 2
        return
    fi

    select choice in "${ports[@]}" "Use default ($DEFAULT_PORT)"; do
        if [[ "$choice" == "Use default ($DEFAULT_PORT)" ]]; then
            PORT="$DEFAULT_PORT"
            break
        elif [[ -n "$choice" ]]; then
            PORT=$(echo "$choice" | awk '{print $1}')
            break
        else
            echo -e "${C_RED}Invalid selection.${C_RESET}"
        fi
    done
}

function select_or_create_project() {
    print_header

    # Use fzf if available for a better experience
    if command -v fzf &> /dev/null; then
        # Get a list of all project directories
        local projects=()
        while IFS= read -r line; do
            projects+=("$line")
        done < <(find "$SKETCH_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

        # Add a static option to create a new project
        projects+=("--- CREATE NEW PROJECT ---")

        local choice
        choice=$(printf '%s\n' "${projects[@]}" | fzf --height 40% --reverse --prompt="Select a project or create a new one: ")

        if [[ -z "$choice" ]]; then
            return # User pressed Esc, so do nothing
        elif [[ "$choice" == "--- CREATE NEW PROJECT ---" ]]; then
            read -rp "Enter new sketch name: " name
            if [[ -n "$name" ]]; then
                arduino-cli sketch new "$SKETCH_DIR/$name"
                PROJECT="$SKETCH_DIR/$name"
            fi
        else
            PROJECT="$SKETCH_DIR/$choice"
        fi
    else
        # Fallback to the original menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better project selection experience.${C_RESET}"
        sleep 2
        print_header
        echo -e "${C_GREEN}==> (1) Select an existing sketch? \n==> (2) Create a new sketch?${C_RESET}"
        read -rp "[1/2]: " menu_choice
        if [[ "$menu_choice" == "2" ]]; then
            read -rp "Enter new sketch name: " name
            if [[ -n "$name" ]]; then
                arduino-cli sketch new "$SKETCH_DIR/$name"
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
        sleep 2
        return
    fi
    echo -e "${C_GREEN}==> Compiling sketch '${PROJECT##*/}'...${C_RESET}"
    arduino-cli compile --fqbn "${FQBN:-$DEFAULT_FQBN}" "$PROJECT"
    press_enter_to_continue
}

function upload_sketch() {
    print_header

    # Check if a project is already selected
    if [[ -n "$PROJECT" && "$PROJECT" != "$DEFAULT_PROJECT" ]]; then
        echo -e "${C_GREEN}==> Current project is '${C_YELLOW}${PROJECT##*/}${C_GREEN}'.${C_RESET}"
        read -rp "Upload this project? [Y/n]: " choice
        # Default to Yes if user just presses Enter
        if [[ -z "$choice" || "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${C_GREEN}==> Uploading sketch '${PROJECT##*/}'...${C_RESET}"
            arduino-cli upload --fqbn "${FQBN:-$DEFAULT_FQBN}" -p "${PORT:-$DEFAULT_PORT}" "$PROJECT" -v
            press_enter_to_continue
            return
        fi
    fi

    # If no project was selected, or user said no, show the selection menu
    print_header # Clear the previous question
    echo -e "${C_GREEN}==> Select a project to upload from $SKETCH_DIR:${C_RESET}"
    
    local current_dir
    current_dir=$(pwd)
    cd "$SKETCH_DIR" || return

    select project_dir in */ "Cancel"; do
        if [[ "$project_dir" == "Cancel" ]]; then
            break # Exit select loop
        elif [[ -n "$project_dir" ]]; then
            local project_path="$SKETCH_DIR/${project_dir%/}"
            echo -e "${C_GREEN}==> Uploading sketch '${project_dir%/}'...${C_RESET}"
            arduino-cli upload --fqbn "${FQBN:-$DEFAULT_FQBN}" -p "${PORT:-$DEFAULT_PORT}" "$project_path" -v
            break # Exit select loop
        else
            echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
        fi
    done

    cd "$current_dir"
    press_enter_to_continue
}

function open_serial() {
    print_header
    echo -e "${C_GREEN}==> Opening Serial Monitor on port ${PORT:-$DEFAULT_PORT}...${C_RESET}"
    echo -e "${C_YELLOW}(Press Ctrl+C to exit)${C_RESET}"
    sleep 1
    arduino-cli monitor -p "${PORT:-$DEFAULT_PORT}" --config 115200
    press_enter_to_continue
}

function install_core() {
    print_header
    echo -e "${C_GREEN}==> Install a new core${C_RESET}"
    local core_name=""

    # Check if fzf is installed for a better experience
    if command -v fzf &> /dev/null; then
        echo -e "${C_GREEN}==> Use the interactive search to find and select a core.${C_RESET}"
        local choice
        choice=$(arduino-cli core search --all | sed '1d' | fzf --height 40% --reverse --prompt="Select a core: ")
        
        if [[ -n "$choice" ]]; then
            core_name=$(echo "$choice" | awk '{print $1}')
        fi
    else
        # Fallback to menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 3

        echo -e "${C_GREEN}==> Available Cores:${C_RESET}"
        mapfile -t all_cores < <(arduino-cli core search --all | sed '1d')

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
        arduino-cli core install "$core_name"
    else
        echo -e "${C_RED}No core selected or entered.${C_RESET}"
        sleep 1
    fi
    press_enter_to_continue
}

function main_menu() {
    while true; do
        print_header
        echo -e "${C_BLUE}1.${C_RESET} List Installed Cores      ${C_BLUE}5.${C_RESET} Select/Create Project"
        echo -e "${C_BLUE}2.${C_RESET} List All Boards           ${C_BLUE}6.${C_RESET} Compile Current Project"
        echo -e "${C_BLUE}3.${C_RESET} Select Board (FQBN)       ${C_BLUE}7.${C_RESET} Upload a Project"
        echo -e "${C_BLUE}4.${C_RESET} Select Port               ${C_BLUE}8.${C_RESET} Open Serial Monitor"
        echo -e "${C_BLUE}9.${C_RESET} Install a Core"
        echo
        echo -e "${C_RED}10. Exit${C_RESET}"
        echo "----------------------------------------------------------"
        read -rp "Choose option: " option

        case $option in
        1) list_installed_boards ;;
        2) list_all_supported_boards ;;
        3) select_board ;;
        4) select_port ;;
        5) select_or_create_project ;;
        6) compile_sketch ;;
        7) upload_sketch ;;
        8) open_serial ;;
        9) install_core ;;
        10) clear; echo "Goodbye!"; break ;;
        *) echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1 ;;
        esac
    done
}

# --- Initialization ---
mkdir -p "$SKETCH_DIR"
main_menu
