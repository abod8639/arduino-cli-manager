#!/bin/bash

# Arduino CLI Manager - UI Module
# This file contains all user interface functions

# --- UI Functions ---

function print_logo() {
                 echo "                                                          "
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
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\\n" "Project:" "${PROJECT:-$DEFAULT_PROJECT}"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\\n" "Board:"   "${FQBN:-   $DEFAULT_FQBN}"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\\n" "Port:"    "${PORT:-   $DEFAULT_PORT}"
                 printf " ${C_YELLOW}%-12s${C_RESET} %s\\n" "Baud:"    "${BAUD:-   $DEFAULT_BAUD}"
                 echo "────────────────────────────────────────────────────────────"
}

function get_version_line() {
    local current="${VERSION#v}"
    local latest="${LATEST_VERSION#v}"

    if [[ -n "$LATEST_VERSION" ]]; then
        vercmp_portable "$latest" "$current"
        local result=$?
        if [[ $result -eq 1 ]]; then
            local update_msg="Update available: v$VERSION → v$LATEST_VERSION"
            printf " ${C_YELLOW}%*s${C_RESET}${C_GREEN}%*s \\n" $(( (59 + ${#update_msg}) / 2 )) "$update_msg" $(( (59 - ${#update_msg}) / 2 )) ""
            return
        fi
    fi

    local version_msg="v$VERSION"
    printf "${C_GREEN} %*s%*s \\n${C_RESET}" $(( (59 + ${#version_msg}) / 2 )) "$version_msg" $(( (59 - ${#version_msg}) / 2 )) ""
}

function press_enter_to_continue() {
    read -p "Press Enter to continue..."
}

function show_help() {
    print_header
    echo -e "${C_GREEN}==> Arduino CLI Manager - Quick Help${C_RESET}"
    echo ""
    echo "This tool helps you manage Arduino projects easily."
    echo ""
    echo -e "${C_CYAN}Getting Started:${C_RESET}"
    echo "  1. Select or create a project (S)"
    echo "  2. Select your board type (B)"
    echo "  3. Connect board and select port (P)"
    echo "  4. Compile your sketch (C)"
    echo "  5. Upload to board (U)"
    echo ""
    echo -e "${C_CYAN}Keyboard Shortcuts:${C_RESET}"
    echo "  S - Select/Create Project    B - Select Board (FQBN)"
    echo "  P - Select Port              C - Compile Project"
    echo "  U - Upload Project           M - Serial Monitor"
    echo "  E - Edit in nvim             L - List Cores"
    echo "  A - List All Boards          I - Install Core"
    echo "  H - Show this help           Q - Quit"
    echo ""
    echo -e "${C_CYAN}Common Workflows:${C_RESET}"
    echo "  ${C_YELLOW}New Project:${C_RESET} S → Create new → B → P → C → U"
    echo "  ${C_YELLOW}Quick Upload:${C_RESET} U (if project already selected)"
    echo "  ${C_YELLOW}Debug Output:${C_RESET} M (opens serial monitor)"
    echo ""
    echo -e "${C_CYAN}Configuration:${C_RESET}"
    echo "  Config file: ~/.arduino-cli-manager.conf"
    echo "  Projects directory: $SKETCH_DIR"
    echo ""
    press_enter_to_continue
}
