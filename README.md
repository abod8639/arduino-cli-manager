# Arduino CLI Manager

![Shell Script](https://img.shields.io/badge/Shell-Bash-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![GitHub Release](https://img.shields.io/github/v/release/abod8639/arduino-cli-manager)



`arduino-cli-manager` is a powerful and user-friendly interactive shell script designed to streamline your Arduino development workflow. It wraps the `arduino-cli` in a colorful, intuitive terminal interface, making it easy to manage boards, ports, and projects without memorizing complex commands.

This script is perfect for developers who prefer working in the terminal and want a more efficient way to compile, upload, and monitor their Arduino sketches.

![image](assets/1.png)

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
  - Libraries
- **Library Management**: Search, install, update, and uninstall Arduino libraries directly from the tool.
- **Automatic Backups**: Creates automatic backups of your projects before uploading (keeps last 5 backups).
- **Operation Logging**: Tracks all operations (uploads, library installations, etc.) with automatic log rotation.
- **Enhanced Error Messages**: Context-specific error messages with actionable troubleshooting suggestions.
- **Built-in Help System**: Quick access to keyboard shortcuts, common workflows, and configuration details.
- **Graceful Fallback**: If `fzf` is not installed, the script provides user-friendly, menu-driven alternatives for all selections.
- **Smart Uploading**: Remembers your last selected project and creates backups before uploading.
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

## Prerequisites

Before you begin, make sure you have the following installed:

- **bash**: The script runs in bash shell (default on most Unix-like systems)
- **arduino-cli**: The Arduino command-line interface (required)
- **jq**: Used for update checks and version management (optional, but recommended)
- **fzf**: For enhanced interactive selection (optional but recommended)
- **nvim**: For integrated project editing (optional)
- **curl**: Used with jq for update checks (optional)

## Installation

### Step 1: `arduino-cli`

1. Install `arduino-cli` using one of these methods:
- **Using curl (recommended)**:
```bash
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
```
- **Using Homebrew (macOS)**:
```bash
brew install arduino-cli
```
For other methods, see the [official Arduino CLI installation guide](https://arduino.github.io/arduino-cli/latest/installation/).

2. Initialize and update the core index:
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

### Step 3: Optional Dependencies

For the best experience, install these additional tools:

#### fzf (Highly Recommended)
The command-line fuzzy finder creates powerful interactive menus:

- **On Debian/Ubuntu:**
  ```bash
  sudo apt install fzf jq curl
  ```
- **On macOS (using Homebrew):**
  ```bash
  brew install fzf jq curl
  ```
- **On Arch Linux:**
  ```bash
  sudo pacman -S fzf jq curl
  ```

The script will fall back to simple menus if `fzf` is not available, and skip update checks if `jq` or `curl` are missing.

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
────────────────────────────────────────────────────────────
 Project:  Not Selected
 Board:    esp32:esp32:esp32 
 Port:     /dev/ttyACM1
 Baud:     115200
────────────────────────────────────────────────────────────
 1 (S) Select/Create Project    
 2 (B) Select Board (FQBN)      
 3 (P) Select Port              
 5 (U) Upload Project           
 4 (C) Compile Project          
 6 (L) List Installed Cores     
 7 (A) List All Supported Boards
 8 (I) Install Core             
 9 (M) Open Serial Monitor      
 0 (E) Edit Project (nvim) 
────────────────────────────────────────────────────────────
 (Q) Quit
────────────────────────────────────────────────────────────
Choose option: 
```

### Menu Options Explained

- **1. Select/Create Project**: Opens an interactive search (`fzf` if available) to choose an existing project or create a new one on the fly.
- **2. Select Board (FQBN)**: Opens an interactive search to filter and select your target board from a complete list.
- **3. Select Port**: Opens an interactive menu to choose from all currently connected serial ports.
- **4. Compile Current Project**: Compiles the sketch in the currently selected project directory.
- **5. Upload a Project**: If a project is already selected, asks for confirmation to upload it. Otherwise, prompts to select a project.
- **6. List Installed Cores**: Shows all board packages currently installed on your system.
- **7. List All Boards**: Lists every board supported by your installed cores, useful for finding the correct FQBN.
- **8. Install a Core**: Helps you install additional board support packages.
- **9. Open Serial Monitor**: Connects to the selected port to view `Serial.print()` output from your board.
- **0. Edit Project (nvim)**: Opens the current project in Neovim for editing.
- **R. Manage Libraries**: Search, install, update, and uninstall Arduino libraries.
- **H. Help**: Shows quick help with keyboard shortcuts and common workflows.
- **q. Exit**: Exits the script.

### Keyboard Shortcuts

For faster access, you can use the following keyboard shortcuts instead of menu numbers. All shortcuts are case-insensitive:

- **s**: Select/Create Project
- **b**: Select Board (FQBN)
- **p**: Select Port
- **c**: Compile Current Project
- **u**: Upload Project
- **l**: List Installed Cores
- **a**: List All Boards
- **i**: Install Core
- **m**: Open Serial Monitor
- **e**: Edit Project (nvim)
- **r**: Manage Libraries
- **h**: Show Help
- **v**: Update Script (when update is available)

### Configuration

You can change the default Board, Port, and the main Arduino sketch directory by editing the configuration variables at the top of the `arduino-cli-manager.sh` script:

```bash
# --- Configuration ---
DEFAULT_FQBN="esp32:esp32:esp32"
DEFAULT_PORT="/dev/ttyACM1"
SKETCH_DIR="$HOME/Arduino"
```

## Common Operations

### Creating a New Project

1. Select option `S` from the main menu
2. Choose "CREATE NEW PROJECT" from the list
3. Enter your project name
4. The script will create a properly structured Arduino sketch

### Uploading to a Board

1. Use option `B` to select your board type (FQBN)
2. Use option `p` to select the correct serial port
3. Select option `U` to upload
4. Choose your project if not already selected

### Monitoring Serial Output

1. Ensure correct port is selected (option `P`)
2. Use option `M` to open the serial monitor
3. Press Ctrl+C to exit the monitor when done

### Managing Libraries

1. Use option `R` to open library management
2. Choose from:
   - Search and install new libraries
   - List currently installed libraries
   - Update all libraries to latest versions
   - Uninstall libraries you no longer need

### Automatic Backups

- Backups are created automatically before each upload
- Located in `~/.arduino-cli-manager/backups/`
- Last 5 backups per project are kept
- Older backups are automatically cleaned up

### Operation Logs

- All operations are logged to `~/.arduino-cli-manager/logs/arduino-manager.log`
- Logs include timestamps, operation type, status, and details
- Automatic log rotation when file exceeds 1MB

## Troubleshooting

### Common Issues

**Upload fails:**
- Check board is properly connected
- Verify correct port is selected
- Try pressing reset button on board
- Close other programs using the serial port

**Compilation errors:**
- Check code for syntax errors
- Ensure all required libraries are installed (use `R` to manage libraries)
- Verify the selected board (FQBN) is correct

**Board not detected:**
- Check USB cable connection
- Try a different USB port
- Install required drivers for your board

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

---

Designed with care and ❤️ by Dexter


