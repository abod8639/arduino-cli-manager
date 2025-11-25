#!/bin/bash
set -o pipefail  # Exit on pipe failures

# Arduino CLI Manager - Main Entry Point
#
# Copyright (c) 2025 abod8639
#
# This script is licensed under the MIT License.
# See the LICENSE file for details.

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all modules in order
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/projects.sh"
source "$SCRIPT_DIR/lib/libraries.sh"
source "$SCRIPT_DIR/lib/boards.sh"
source "$SCRIPT_DIR/lib/ports.sh"
source "$SCRIPT_DIR/lib/sketch.sh"
source "$SCRIPT_DIR/lib/cores.sh"

# --- Main Menu ---
function main_menu() {
    while true; do
        print_header
        echo -e " ${C_YELLOW}1 (S) S${C_RESET}elect/Create Project    "
        echo -e " ${C_YELLOW}2 (B)${C_RESET} Select ${C_YELLOW}B${C_RESET}oard (FQBN)      "
        echo -e " ${C_YELLOW}3 (P)${C_RESET} Select ${C_YELLOW}P${C_RESET}ort              "
        echo -e " ${C_YELLOW}4 (C) C${C_RESET}ompile Project          "
        echo -e " ${C_YELLOW}5 (U) U${C_RESET}pload Project           "
        echo -e " ${C_YELLOW}6 (L) L${C_RESET}ist Installed Cores     "
        echo -e " ${C_YELLOW}7 (A)${C_RESET} List ${C_YELLOW}A${C_RESET}ll Supported Boards"
        echo -e " ${C_YELLOW}8 (I) I${C_RESET}nstall Core             " 
        echo -e " ${C_YELLOW}9 (M)${C_RESET} Open Serial ${C_YELLOW}M${C_RESET}onitor      "
        echo -e " ${C_YELLOW}0 (E) E${C_RESET}dit Project (nvim)      "
        echo "────────────────────────────────────────────────────────────"
        echo -e " ${C_CYAN}(R)${C_RESET} Manage Libraries"
        echo -e " ${C_CYAN}(H)${C_RESET} Help"
        
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
            [rR]) manage_libraries ;;
            [hH]) show_help ;;

            [vV]) 
                if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
                    update_script
                else
                    echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1
                fi
                ;;

            [qQ]) 
                clear
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
