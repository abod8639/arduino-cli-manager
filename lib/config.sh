#!/bin/bash

# Arduino CLI Manager - Configuration Module
# This file contains all configuration variables and constants

# --- Version ---
VERSION="2.0.0"

# --- Default Configuration ---
DEFAULT_FQBN="esp32:esp32:esp32"
DEFAULT_PORT="/dev/ttyACM1"
DEFAULT_BAUD="115200"
DEFAULT_PROJECT="Not Selected"

# --- Directories ---
SKETCH_DIR="$HOME/Arduino"
CONFIG_FILE="$HOME/.arduino-cli-manager.conf"
BACKUP_DIR="$HOME/.arduino-cli-manager/backups"
LOG_DIR="$HOME/.arduino-cli-manager/logs"
LOG_FILE="$LOG_DIR/arduino-manager.log"

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
LATEST_VERSION=""
