#!/bin/bash

# Arduino CLI Manager - Projects Module
# This file contains project management functions

function select_or_create_project() {
    print_header

    if command -v fzf &> /dev/null; then 
        # Find projects using fd or find (without eval for security)
        local projects
        if command -v fd &> /dev/null; then
            projects=$(fd . "$SKETCH_DIR" --type d --max-depth 1)
        else
            projects=$(find "$SKETCH_DIR" -mindepth 1 -maxdepth 1 -type d)
        fi

        local choice
        choice=$( (echo "--- CREATE NEW PROJECT ---"; echo "--- BROWSE CUSTOM PATH ---"; echo "$projects") | \
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
        elif [[ "$choice" == "--- BROWSE CUSTOM PATH ---" ]]; then
            browse_custom_path
        else
            PROJECT="$choice"
        fi
    else
        # Fallback to the original menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better project selection experience.${C_RESET}"
        sleep 1
        print_header
        echo -e "${C_GREEN}==> (1) Select an existing sketch\n==> (2) Create a new sketch\n==> (3) Browse custom path${C_RESET}"
        read -rp "[1/2/3]: " menu_choice
        if [[ "$menu_choice" == "2" ]]; then
            read -rp "Enter new sketch name: " name
            if [[ -n "$name" ]]; then
                run_arduino_cli_command sketch new "$SKETCH_DIR/$name"
                PROJECT="$SKETCH_DIR/$name"
            fi
        elif [[ "$menu_choice" == "3" ]]; then
            browse_custom_path
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

function browse_custom_path() {
    print_header
    echo -e "${C_GREEN}==> Browse for Arduino project${C_RESET}"
    echo ""
    
    if command -v fzf &> /dev/null; then
        # Interactive directory browsing with fzf
        echo -e "${C_CYAN}Use fzf to browse directories interactively${C_RESET}"
        echo -e "${C_YELLOW}Tip: Type to filter, Enter to select, Esc to cancel${C_RESET}"
        echo ""
        
        local start_dir="${1:-$HOME}"
        local selected_dir
        
        # Use fd if available for faster directory listing, otherwise use find
        if command -v fd &> /dev/null; then
            selected_dir=$(fd . "$start_dir" --type d --max-depth 5 --hidden --exclude .git | \
                fzf --reverse \
                    --prompt="Select Arduino project directory > " \
                    --header="Browse directories (type to filter, Enter to select)" \
                    --preview='ls -lah {} 2>/dev/null | head -20' \
                    --preview-window=right:50%:wrap \
                    --height=80%)
        else
            selected_dir=$(find "$start_dir" -maxdepth 5 -type d ! -path "*/\.*" 2>/dev/null | \
                fzf --reverse \
                    --prompt="Select Arduino project directory > " \
                    --header="Browse directories (type to filter, Enter to select)" \
                    --preview='ls -lah {} 2>/dev/null | head -20' \
                    --preview-window=right:50%:wrap \
                    --height=80%)
        fi
        
        if [[ -z "$selected_dir" ]]; then
            echo -e "${C_YELLOW}No directory selected.${C_RESET}"
            sleep 1
            return
        fi
        
        custom_path="$selected_dir"
    else
        # Fallback to manual path entry if fzf is not available
        echo -e "${C_YELLOW}Tip: Install 'fzf' for interactive directory browsing${C_RESET}"
        echo -e "${C_YELLOW}Enter the full path to your Arduino project directory${C_RESET}"
        echo -e "${C_CYAN}(The directory should contain a .ino file)${C_RESET}"
        echo ""
        
        read -rp "Path: " custom_path
        
        # Expand ~ to home directory
        custom_path="${custom_path/#\~/$HOME}"
        
        if [[ -z "$custom_path" ]]; then
            echo -e "${C_RED}No path entered.${C_RESET}"
            sleep 1
            return
        fi
    fi
    
    # Validate the selected path
    if [[ ! -d "$custom_path" ]]; then
        echo -e "${C_RED}Error: Directory does not exist: $custom_path${C_RESET}"
        sleep 2
        return
    fi
    
    # Check if it contains .ino files
    local ino_count=$(find "$custom_path" -maxdepth 1 -name "*.ino" -type f 2>/dev/null | wc -l)
    
    if [[ $ino_count -eq 0 ]]; then
        echo -e "${C_YELLOW}Warning: No .ino files found in this directory.${C_RESET}"
        echo -e "${C_CYAN}Found in: $custom_path${C_RESET}"
        read -rp "Use this path anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${C_RED}Cancelled.${C_RESET}"
            sleep 1
            return
        fi
    else
        echo -e "${C_GREEN}Found $ino_count .ino file(s) in this directory ✓${C_RESET}"
    fi
    
    PROJECT="$custom_path"
    echo -e "${C_GREEN}Selected project: ${C_YELLOW}$PROJECT${C_RESET}"
    sleep 1
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
    
    # Change to the project directory and open the main .ino file
    (
        cd "$PROJECT" && nvim "${project_name}.ino"
    )
    
    echo # Add a newline for better formatting after nvim exits
}
