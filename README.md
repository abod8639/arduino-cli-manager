# My Arduino Project

This project provides a complete and professional environment for Arduino development using `arduino-cli`.

## Features

- **Interactive Project Management:** A shell script (`arduino_manager.sh`) to manage boards, ports, and projects.
- **Automated Builds:** A `build.sh` script for quick compilation and uploading.
- **Makefile Integration:** A `Makefile` for standard build automation.
- **Structured Project:** A clean and organized folder structure.

## Installation

### 1. Install `arduino-cli`

Follow the official instructions to install `arduino-cli` on your system:
[https://arduino.github.io/arduino-cli/latest/installation/](https://arduino.github.io/arduino-cli/latest/installation/)

### 2. Install Board Cores

Install the necessary board cores. For example, to install the ESP32 core:

```bash
arduino-cli core install esp32:esp32
```

## Usage

### `arduino_manager.sh`

This interactive script helps you manage your Arduino projects.

**To run:**

```bash
./arduino_manager.sh
```

**Example Output:**

```
====== Arduino CLI Tool ======
1. List installed boards
2. List all supported boards
3. Select board
4. Select port
5. Select or create project
6. Compile sketch
7. Upload sketch
8. Open Serial Monitor
9. Exit
Choose option: 
```

### `build.sh`

This script compiles and uploads the sketch. You can override the default board and port using environment variables.

**To run:**

```bash
./build.sh
```

**With custom settings:**

```bash
BOARD_FQBN="arduino:avr:uno" PORT="/dev/ttyUSB0" ./build.sh
```

### `Makefile`

The `Makefile` provides several targets for common tasks.

- `make compile`: Compiles the sketch.
- `make upload`: Uploads the sketch.
- `make build`: Compiles and uploads the sketch.
- `make monitor`: Opens the serial monitor.
- `make clean`: Cleans the build directory.

**To run:**

```bash
make build
```

**With custom settings:**

```bash
make build BOARD_FQBN="arduino:avr:uno" PORT="/dev/ttyUSB0"
```
# arduino-cli-manager
