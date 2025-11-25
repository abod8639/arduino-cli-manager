#!/bin/bash

# Arduino CLI Manager - Uninstallation Script

set -e

# Colors
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_RESET='\033[0m'

echo -e "${C_YELLOW}Arduino CLI Manager - Uninstallation${C_RESET}"
echo ""

INSTALL_DIR="$HOME/.local/bin"
INSTALL_NAME="arduino-manager"

if [ -f "$INSTALL_DIR/$INSTALL_NAME" ]; then
    rm "$INSTALL_DIR/$INSTALL_NAME"
    echo -e "${C_GREEN}✓ Removed $INSTALL_DIR/$INSTALL_NAME${C_RESET}"
else
    echo -e "${C_YELLOW}Tool not found in $INSTALL_DIR${C_RESET}"
fi

echo ""
echo "Note: You may want to remove the alias from ~/.bashrc manually:"
echo "  alias acm='arduino-manager'"
echo ""
echo -e "${C_GREEN}Uninstallation complete!${C_RESET}"
