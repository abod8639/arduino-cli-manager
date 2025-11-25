#!/bin/bash

# Arduino CLI Manager - Cores Module
# This file contains core management and update functions

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
