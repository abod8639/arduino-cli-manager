# Arduino CLI Manager

![Shell Script](https://img.shields.io/badge/Shell-Bash-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

`arduino-cli-manager` is a powerful and user-friendly interactive shell script designed to streamline your Arduino development workflow. It wraps the `arduino-cli` in a colorful, intuitive terminal interface, making it easy to manage boards, ports, and projects without memorizing complex commands.

This script is perfect for developers who prefer working in the terminal and want a more efficient way to compile, upload, and monitor their Arduino sketches.

## Table of Contents

- [Key Features](#key-features)
- [Installation](#installation)
  - [Step 1: `arduino-cli`](#step-1-arduino-cli)
  - [Step 2: Board Cores](#step-2-board-cores)
  - [Step 3: `fzf` (Highly Recommended)](#step-3-fzf-highly-recommended)
- [How to Use](#how-to-use)
  - [Linux and macOS](#linux-and-macos)
  - [Windows](#windows)
  - [The Main Menu](#the-main-menu)
  - [Menu Options Explained](#menu-options-explained)
- [Configuration](#configuration)

## Key Features

- **Intuitive Interactive Menu**: A clean, color-coded, and easy-to-navigate main menu.
- **Persistent Configuration Display**: The header always shows your currently selected Board, Port, and Project, so you never lose context.
- **Powerful Fuzzy Searching**: Automatically uses `fzf` (if installed) for lightning-fast, interactive searching and filtering of:
  - Boards (FQBN)
  - Projects
  - Serial Ports
- **Graceful Fallback**: If `fzf` is not installed, the script provides user-friendly, menu-driven alternatives for all selections.
- **Smart Uploading**: Remembers your last selected project and asks for confirmation before uploading, saving you time.
- **Create Projects on the Fly**: An integrated option to create a new, properly structured Arduino sketch directly from the project selection menu.
- **Self-Contained & Portable**: A single script with no complex dependencies other than `arduino-cli`.

## Get the Tool

You can download or clone the `arduino-cli-manager` from its GitHub repository:

[https://github.com/abod8639/arduino-cli-manager](https://github.com/abod8639/arduino-cli-manager)

To get started, simply clone the repository:

```bash
git clone https://github.com/abod8639/arduino-cli-manager.git
cd arduino-cli-manager
```

For detailed instructions on how to install dependencies and use the tool, please refer to the [Installation](#installation) and [How to Use](#how-to-use) sections below.

## Installation

### Step 1: `arduino-cli`

First, ensure you have `arduino-cli` installed and configured on your system. For detailed installation instructions for your operating system, please refer to the [official Arduino CLI installation guide](https://arduino.github.io/arduino-cli/latest/installation/).

After installing `arduino-cli`, initialize it and update the core index:
```bash
arduino-cli config init
arduino-cli core update-index
```

### Step 2: Board Cores

Install the board cores for the microcontrollers you work with. For example, to install the ESP32 core:

```bash
arduino-cli core update-index
arduino-cli core install esp32:esp32
arduino-cli core install arduino:samd
```

### Step 3: `fzf` (Highly Recommended)

For the best experience, install the command-line fuzzy finder `fzf`. The script will automatically use it to create powerful interactive menus.

- **On Debian/Ubuntu:**
  ```bash
  sudo apt install fzf
  ```
- **On macOS (using Homebrew):**
  ```bash
  brew install fzf
  ```
- **On Arch Linux:**
  ```bash
  sudo pacman -S fzf
  ```

## How to Use

`arduino-cli-manager` is a shell script designed for Unix-like environments (Linux, macOS, WSL/Git Bash on Windows).

1.  **Get the Script:** If you haven't already, clone the repository:
    ```bash
    git clone https://github.com/abod8639/arduino-cli-manager.git
    cd arduino-cli-manager
    ```
2.  **Make Executable:** Give execute permissions to the script:
    ```bash
    chmod +x arduino-cli-manager.sh
    ```
3.  **Run the Script:** Execute the script from its directory:
    ```bash
    ./arduino-cli-manager.sh
    ```
    *Tip: For convenience, you can move the script to a directory in your system's PATH (e.g., `/usr/local/bin`) to run it from any location. For example: `sudo mv arduino-cli-manager.sh /usr/local/bin/arduino-manager`.*

### The Main Menu

You will be greeted by the main menu, which always displays your current settings at the top.

```
  ██████╗  █████╗ ██████╗  ██╗   ██╗██╗███╗   ██╗ ██████╗
  ██╔══██╗██╔══██╗██╔══██╗ ██║   ██║██║████╗  ██║██╔═══██╗
  ██████╔╝███████║██║  ██║ ██║   ██║██║██╔██╗ ██║██║   ██║
  ██╔══██║██╔══██║██║  ██║ ██║   ██║██║██║╚██╗██║██║   ██║
  ██████╔╝██║  ██║██████╔╝ ╚██████╔╝██║██║ ╚████║╚██████╔╝
  ╚═════╝ ╚═╝  ╚═╝╚═════╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝
 ┌────────────────────────────────────────────────────────┐       
 │                 ARDUINO CLI MANAGER                    │       
 │                                                        │       
 │ Select board, serial, compile, upload & monitor easily │       
 └────────────────────────────────────────────────────────┘       
───────────────────────────────────────────────────────────
 Board:    esp32:esp32:esp32 
 Port:     /dev/ttyACM1
 Baud:        115200
 Project:  Not Selected
───────────────────────────────────────────────────────────
1. Select/Create Project          6. List Installed Cores
2. Select Board (FQBN)            7. List All Boards
3. Select Port                    8. Install a Core
4. Compile Current Project        9. Open Serial Monitor
5. Upload a Project

0. Exit
───────────────────────────────────────────────────────────
Choose option: 
```

### Menu Options Explained

- **1. List Installed Cores**: Shows the board packages you have installed.
- **2. List All Boards**: Lists every board supported by your installed cores. Useful for finding the correct FQBN.
- **3. Select Board (FQBN)**: Opens an interactive search (`fzf` if available) to filter and select your target board from a complete list.
- **4. Select Port**: Opens an interactive menu (`fzf` if available) to choose from all currently connected serial ports.
- **5. Select/Create Project**: Opens an interactive search (`fzf` if available) to choose an existing project or create a new one on the fly.
- **6. Compile Current Project**: Compiles the sketch in the currently selected project directory.
- **7. Upload a Project**: If a project is already selected, it asks for confirmation to upload it. If not, it prompts you to select a project to upload.
- **8. Open Serial Monitor**: Connects to the selected port to view `Serial.print()` output from your board.
- **9. Exit**: Exits the script.

### Configuration

You can change the default Board, Port, and the main Arduino sketch directory by editing the configuration variables at the top of the `arduino-cli-manager.sh` script:

```bash
# --- Configuration ---
DEFAULT_FQBN="esp32:esp32:esp32"
DEFAULT_PORT="/dev/ttyACM1"
SKETCH_DIR="$HOME/Arduino"
```