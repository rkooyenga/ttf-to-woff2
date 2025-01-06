#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Log file
LOG_FILE="font_conversion.log"

# Progress bar function
progress_bar() {
    local progress=$1
    local total=$2
    local bar_width=30
    local percent=$((progress * 100 / total))
    local filled=$((progress * bar_width / total))
    local empty=$((bar_width - filled))

    echo -ne "[ ${GREEN}"
    for ((i = 0; i < filled; i++)); do echo -n "#"; done
    echo -ne "${RESET}"
    for ((i = 0; i < empty; i++)); do echo -n " "; done
    echo -ne " ] ${CYAN}${percent}%${RESET}\r"
}

# Confirm the fonts folder
echo -e "${CYAN}Would you like to convert fonts in the user folder (~/.local/share/fonts) or system folder (/usr/share/fonts)?${RESET}"
echo -e "${YELLOW}Type 'user' or 'system':${RESET} "
read -r FOLDER_CHOICE

if [[ $FOLDER_CHOICE == "user" ]]; then
    FONT_DIR="$HOME/.local/share/fonts"
elif [[ $FOLDER_CHOICE == "system" ]]; then
    FONT_DIR="/usr/share/fonts"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}System folder requires sudo. Please run the script as root.${RESET}"
        exit 1
    fi
else
    echo -e "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
fi

# Check if the directory exists
if [[ ! -d $FONT_DIR ]]; then
    echo -e "${RED}The directory $FONT_DIR does not exist. Exiting.${RESET}"
    exit 1
fi

# Initialize log file
echo "Font Conversion Log" > "$LOG_FILE"
echo "===================" >> "$LOG_FILE"

# Find and process .ttf files
TTF_FILES=$(find "$FONT_DIR" -type f -name "*.ttf" -o -name "*.TTF")
TOTAL_FILES=$(echo "$TTF_FILES" | wc -l)

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo -e "${YELLOW}No .ttf files found in $FONT_DIR.${RESET}"
    exit 0
fi

echo -e "${CYAN}Found $TOTAL_FILES .ttf files. Starting conversion...${RESET}"

# Convert files
COUNT=0
while IFS= read -r TTF_FILE; do
    OUTPUT_DIR=$(dirname "$TTF_FILE")
    BASE_NAME=$(basename "$TTF_FILE" .ttf)
    WOFF2_FILE="$OUTPUT_DIR/$BASE_NAME.woff2"

    # Convert using brotli
    /usr/bin/brotli --input "$TTF_FILE" --output "$WOFF2_FILE" --best

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Converted: $BASE_NAME to $WOFF2_FILE${RESET}"
        echo "Converted: $BASE_NAME -> $WOFF2_FILE" >> "$LOG_FILE"
    else
        echo -e "${RED}Failed to convert: $BASE_NAME${RESET}"
    fi

    # Update progress bar
    ((COUNT++))
    progress_bar $COUNT $TOTAL_FILES
done <<< "$TTF_FILES"

# Finalize
echo
echo -e "${GREEN}Conversion completed. Log saved to $LOG_FILE.${RESET}"
