#!/bin/bash

# Arduino CLI Manager - Libraries Module
# This file contains library management functions

function manage_libraries() {
    while true; do
        print_header
        echo -e "${C_GREEN}==> Library Management${C_RESET}"
        echo ""
        echo -e " ${C_YELLOW}1${C_RESET} Search and Install Library"
        echo -e " ${C_YELLOW}2${C_RESET} List Installed Libraries"
        echo -e " ${C_YELLOW}3${C_RESET} Update All Libraries"
        echo -e " ${C_YELLOW}4${C_RESET} Uninstall Library"
        echo -e " ${C_YELLOW}5${C_RESET} Back to Main Menu"
        echo ""
        read -rp "Enter your choice: " -n 1 lib_option
        echo ""
        
        case $lib_option in
            1) install_library ;;
            2) list_libraries ;;
            3) update_libraries ;;
            4) uninstall_library ;;
            5) return ;;
            *) echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1 ;;
        esac
    done
}

function install_library() {
    print_header
    echo -e "${C_GREEN}==> Search for libraries${C_RESET}"
    read -rp "Enter search term: " search_term
    
    if [[ -z "$search_term" ]]; then
        echo -e "${C_RED}Search term cannot be empty.${C_RESET}"
        sleep 1
        return
    fi
    
    echo -e "${C_CYAN}Searching for '$search_term'...${C_RESET}"
    local libs
    libs=$(arduino-cli lib search "$search_term" 2>/dev/null | sed '1d')
    
    if [[ -z "$libs" ]]; then
        echo -e "${C_RED}No libraries found matching '$search_term'.${C_RESET}"
        press_enter_to_continue
        return
    fi
    
    if command -v fzf &> /dev/null; then
        local choice
        choice=$(echo "$libs" | fzf --reverse --prompt="Select library: " --header="Enter to install")
        
        if [[ -n "$choice" ]]; then
            local lib_name
            lib_name=$(echo "$choice" | awk '{print $1}')
            echo -e "${C_GREEN}Installing $lib_name...${C_RESET}"
            if arduino-cli lib install "$lib_name"; then
                echo -e "${C_GREEN}Library installed successfully!${C_RESET}"
                log_operation "LIBRARY_INSTALL" "SUCCESS" "$lib_name"
            else
                echo -e "${C_RED}Failed to install library.${C_RESET}"
                log_operation "LIBRARY_INSTALL" "FAILED" "$lib_name"
            fi
        fi
    else
        echo "$libs"
        echo ""
        read -rp "Enter library name to install: " lib_name
        if [[ -n "$lib_name" ]]; then
            echo -e "${C_GREEN}Installing $lib_name...${C_RESET}"
            if arduino-cli lib install "$lib_name"; then
                echo -e "${C_GREEN}Library installed successfully!${C_RESET}"
                log_operation "LIBRARY_INSTALL" "SUCCESS" "$lib_name"
            else
                echo -e "${C_RED}Failed to install library.${C_RESET}"
                log_operation "LIBRARY_INSTALL" "FAILED" "$lib_name"
            fi
        fi
    fi
    press_enter_to_continue
}

function list_libraries() {
    print_header
    echo -e "${C_GREEN}==> Installed Libraries:${C_RESET}"
    arduino-cli lib list
    echo ""
    press_enter_to_continue
}

function update_libraries() {
    print_header
    echo -e "${C_GREEN}==> Updating all libraries...${C_RESET}"
    if arduino-cli lib upgrade; then
        echo -e "${C_GREEN}All libraries updated successfully!${C_RESET}"
        log_operation "LIBRARY_UPDATE" "SUCCESS" "All libraries"
    else
        echo -e "${C_RED}Failed to update libraries.${C_RESET}"
        log_operation "LIBRARY_UPDATE" "FAILED" "All libraries"
    fi
    press_enter_to_continue
}

function uninstall_library() {
    print_header
    echo -e "${C_GREEN}==> Installed Libraries:${C_RESET}"
    local installed_libs
    installed_libs=$(arduino-cli lib list 2>/dev/null | awk 'NR>1 {print $1}')
    
    if [[ -z "$installed_libs" ]]; then
        echo -e "${C_RED}No libraries installed.${C_RESET}"
        press_enter_to_continue
        return
    fi
    
    if command -v fzf &> /dev/null; then
        local choice
        choice=$(echo "$installed_libs" | fzf --reverse --prompt="Select library to uninstall: ")
        
        if [[ -n "$choice" ]]; then
            echo -e "${C_YELLOW}Uninstalling $choice...${C_RESET}"
            if arduino-cli lib uninstall "$choice"; then
                echo -e "${C_GREEN}Library uninstalled successfully!${C_RESET}"
                log_operation "LIBRARY_UNINSTALL" "SUCCESS" "$choice"
            else
                echo -e "${C_RED}Failed to uninstall library.${C_RESET}"
                log_operation "LIBRARY_UNINSTALL" "FAILED" "$choice"
            fi
        fi
    else
        echo "$installed_libs"
        echo ""
        read -rp "Enter library name to uninstall: " lib_name
        if [[ -n "$lib_name" ]]; then
            echo -e "${C_YELLOW}Uninstalling $lib_name...${C_RESET}"
            if arduino-cli lib uninstall "$lib_name"; then
                echo -e "${C_GREEN}Library uninstalled successfully!${C_RESET}"
                log_operation "LIBRARY_UNINSTALL" "SUCCESS" "$lib_name"
            else
                echo -e "${C_RED}Failed to uninstall library.${C_RESET}"
                log_operation "LIBRARY_UNINSTALL" "FAILED" "$lib_name"
            fi
        fi
    fi
    press_enter_to_continue
}
