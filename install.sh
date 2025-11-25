#!/bin/bash

# Arduino CLI Manager - Installation Script
# Cross-platform installation for bash, zsh, macOS, and Linux

set -e

# Colors
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_RED='\033[0;31m'
C_RESET='\033[0m'

echo -e "${C_GREEN}Arduino CLI Manager - Installation${C_RESET}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation directory
INSTALL_DIR="$HOME/.local/bin"
INSTALL_NAME="arduino-manager"

# Detect shell and RC file
detect_shell() {
    local shell_name=$(basename "$SHELL")
    local rc_file=""
    
    case "$shell_name" in
        zsh)
            rc_file="$HOME/.zshrc"
            ;;
        bash)
            rc_file="$HOME/.bashrc"
            ;;
        *)
            # Try to detect by checking which files exist
            if [ -f "$HOME/.zshrc" ]; then
                rc_file="$HOME/.zshrc"
            elif [ -f "$HOME/.bashrc" ]; then
                rc_file="$HOME/.bashrc"
            else
                rc_file="$HOME/.profile"
            fi
            ;;
    esac
    
    echo "$rc_file"
}

RC_FILE=$(detect_shell)
SHELL_NAME=$(basename "$SHELL")

echo -e "${C_CYAN}Detected shell: $SHELL_NAME${C_RESET}"
echo -e "${C_CYAN}Using RC file: $RC_FILE${C_RESET}"
echo ""

# Create installation directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${C_YELLOW}Creating $INSTALL_DIR...${C_RESET}"
    mkdir -p "$INSTALL_DIR"
fi

# Check if directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${C_YELLOW}Warning: $INSTALL_DIR is not in your PATH${C_RESET}"
    echo ""
    echo "The following line needs to be added to $RC_FILE:"
    echo -e "${C_GREEN}export PATH=\"\$HOME/.local/bin:\$PATH\"${C_RESET}"
    echo ""
    read -rp "Do you want to add it automatically? [y/N]: " add_path
    
    if [[ "$add_path" =~ ^[Yy]$ ]]; then
        # Check if already exists
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$RC_FILE" 2>/dev/null && \
           ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$RC_FILE" 2>/dev/null; then
            echo '' >> "$RC_FILE"
            echo '# Added by arduino-cli-manager installer' >> "$RC_FILE"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC_FILE"
            echo -e "${C_GREEN}✓ Added to $RC_FILE${C_RESET}"
            echo -e "Run: ${C_CYAN}source $RC_FILE${C_RESET}"
        else
            echo -e "${C_YELLOW}PATH export already exists in $RC_FILE${C_RESET}"
        fi
    fi
fi

# Create wrapper script
echo -e "${C_YELLOW}Creating wrapper script...${C_RESET}"

cat > "$INSTALL_DIR/$INSTALL_NAME" << EOF
#!/bin/bash

# Arduino CLI Manager - Global Wrapper
# This script allows running arduino-cli-manager from anywhere

# Get the installation directory
MANAGER_DIR="$SCRIPT_DIR"

# Change to manager directory and run
cd "\$MANAGER_DIR" && ./arduino-cli-manager.sh "\$@"
EOF

# Make executable
chmod +x "$INSTALL_DIR/$INSTALL_NAME"

echo -e "${C_GREEN}✓ Installation complete!${C_RESET}"
echo ""
echo "You can now run the tool from anywhere using:"
echo -e "${C_GREEN}  $INSTALL_NAME${C_RESET}"
echo ""
echo "Or create an alias for quick access:"
echo -e "${C_GREEN}  alias acm='$INSTALL_NAME'${C_RESET}"
echo ""

# Offer to create alias
read -rp "Do you want to create the 'acm' alias now? [y/N]: " create_alias

if [[ "$create_alias" =~ ^[Yy]$ ]]; then
    if ! grep -q "alias acm=" "$RC_FILE" 2>/dev/null; then
        echo '' >> "$RC_FILE"
        echo '# Arduino CLI Manager alias' >> "$RC_FILE"
        echo "alias acm='$INSTALL_NAME'" >> "$RC_FILE"
        echo -e "${C_GREEN}✓ Alias 'acm' added to $RC_FILE${C_RESET}"
        echo -e "Run: ${C_CYAN}source $RC_FILE${C_RESET}"
    else
        echo -e "${C_YELLOW}Alias 'acm' already exists in $RC_FILE${C_RESET}"
    fi
fi

echo ""
echo -e "${C_GREEN}╔════════════════════════════════════════╗${C_RESET}"
echo -e "${C_GREEN}║        Installation Successful!        ║${C_RESET}"
echo -e "${C_GREEN}╚════════════════════════════════════════╝${C_RESET}"
echo ""
echo "Next steps:"
echo -e "1. ${C_CYAN}source $RC_FILE${C_RESET}  (to reload shell config)"
echo -e "2. ${C_CYAN}$INSTALL_NAME${C_RESET} or ${C_CYAN}acm${C_RESET}  (to run the tool)"
echo ""
