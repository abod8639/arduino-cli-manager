#!/usr/bin/env bash

# Mock functions for external commands used in tests

# Mock arduino-cli command
arduino-cli() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        "version")
            echo "arduino-cli  Version: 0.35.0 Commit: 1234567 Date: 2024-01-01T00:00:00Z"
            ;;
        "board")
            local subcmd="$1"
            case "$subcmd" in
                "list")
                    cat << EOF
Port         Protocol Type              Board Name          FQBN                        Core
/dev/ttyACM0 serial   Serial Port (USB) Arduino Uno         arduino:avr:uno             arduino:avr
/dev/ttyUSB0 serial   Serial Port (USB) ESP32 Dev Module    esp32:esp32:esp32           esp32:esp32
EOF
                    ;;
                "listall")
                    cat << EOF
Board Name                    FQBN
Arduino Uno                   arduino:avr:uno
Arduino Mega                  arduino:avr:mega
ESP32 Dev Module              esp32:esp32:esp32
ESP8266 Generic               esp8266:esp8266:generic
EOF
                    ;;
            esac
            ;;
        "core")
            local subcmd="$1"
            case "$subcmd" in
                "list")
                    cat << EOF
ID              Installed Latest Name
arduino:avr     1.8.6     1.8.6  Arduino AVR Boards
esp32:esp32     2.0.14    2.0.14 ESP32 Arduino
EOF
                    ;;
                "search")
                    cat << EOF
ID              Version Name
arduino:avr     1.8.6   Arduino AVR Boards
arduino:samd    1.8.13  Arduino SAMD Boards
esp32:esp32     2.0.14  ESP32 Arduino
esp8266:esp8266 3.1.2   ESP8266 Community
EOF
                    ;;
                "install")
                    echo "Installing $2..."
                    return 0
                    ;;
            esac
            ;;
        "lib")
            local subcmd="$1"
            case "$subcmd" in
                "list")
                    cat << EOF
Name           Installed Available Location              Description
WiFi           1.2.7     -         BUILTIN              -
Servo          1.2.1     1.2.2     USER                 Servo motor library
Adafruit_GFX   1.11.9    1.11.9    USER                 Graphics library
EOF
                    ;;
                "search")
                    cat << EOF
Name           Version Author              Description
WiFi           1.2.7   Arduino             WiFi library
Servo          1.2.2   Arduino             Servo motor control
Adafruit_GFX   1.11.9  Adafruit            Graphics library
DHT            1.4.4   Adafruit            DHT sensor library
EOF
                    ;;
                "install")
                    echo "Installing $2..."
                    return 0
                    ;;
                "uninstall")
                    echo "Uninstalling $2..."
                    return 0
                    ;;
                "upgrade")
                    echo "Upgrading all libraries..."
                    return 0
                    ;;
            esac
            ;;
        "compile")
            echo "Compiling sketch..."
            echo "Sketch uses 1234 bytes (3%) of program storage space."
            return 0
            ;;
        "upload")
            echo "Uploading sketch..."
            echo "Upload successful!"
            return 0
            ;;
        "sketch")
            local subcmd="$1"
            if [[ "$subcmd" == "new" ]]; then
                local sketch_name="$2"
                mkdir -p "$sketch_name"
                echo "void setup() {}" > "$sketch_name/${sketch_name##*/}.ino"
                echo "void loop() {}" >> "$sketch_name/${sketch_name##*/}.ino"
                return 0
            fi
            ;;
        "monitor")
            echo "Opening serial monitor..."
            return 0
            ;;
    esac
}

# Mock fzf command
fzf() {
    # Return first line of input (simulates user selection)
    head -n 1
}

# Mock nvim command
nvim() {
    # Do nothing, just return success
    return 0
}

# Mock fd command
fd() {
    # Simulate fd output
    find "$2" -type d -maxdepth "${4:-1}" 2>/dev/null
}

# Mock curl for update checks
curl() {
    if [[ "$*" == *"github.com"* ]]; then
        echo '{"tag_name": "v1.0.9"}'
    fi
}

# Mock jq
jq() {
    if [[ "$1" == "-e" ]]; then
        return 0
    elif [[ "$1" == "-r" ]]; then
        echo "1.0.9"
    fi
}

# Export mock functions
export -f arduino-cli
export -f fzf
export -f nvim
export -f fd
export -f curl
export -f jq
