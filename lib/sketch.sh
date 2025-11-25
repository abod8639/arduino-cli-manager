#!/bin/bash

# Arduino CLI Manager - Sketch Module
# This file contains sketch compilation and upload functions

function compile_sketch() {
    print_header
    if [[ -z "${PROJECT:-}" || "$PROJECT" == "$DEFAULT_PROJECT" ]]; then
        echo -e "${C_RED}No project selected. Please select a project first.${C_RESET}"
        sleep 1
        return 1
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

    # 1.5 Create backup before upload
    echo -e "${C_CYAN}Creating backup before upload...${C_RESET}"
    backup_project "$project_to_upload"
    echo ""

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
    log_operation "UPLOAD" "SUCCESS" "${project_to_upload##*/} to $upload_port"
    

}
