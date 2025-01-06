#!/bin/bash

# title: ttf-to-woff2.sh
# author: ray kooyenga
# date: 01-05-2024
# github: https://github.com/rkooyenga/ttf-to-woff2
# gh page: https://rkooyenga.github.io/ttf-to-woff2

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
echo -e "${CYAN}Choose the fonts folder:${RESET}"
echo -e "${YELLOW}1) User folder (~/.local/share/fonts)${RESET}"
echo -e "${YELLOW}2) System folder (/usr/share/fonts)${RESET}"
echo -e "${YELLOW}3) Other (specify a directory)${RESET}"
read -rp "Enter your choice (1/2/3): " FOLDER_CHOICE

case $FOLDER_CHOICE in
    1)
        FONT_DIR="$HOME/.local/share/fonts"
        ;;
    2)
        FONT_DIR="/usr/share/fonts"
        if [[ $EUID -ne 0 ]]; then
            echo -e "${RED}System folder requires sudo. Please run the script as root.${RESET}"
            exit 1
        fi
        ;;
    3)
        read -rp "Enter the full path to the custom fonts directory: " FONT_DIR
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${RESET}"
        exit 1
        ;;
esac

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

    # Skip if .woff2 file already exists
    if [[ -f $WOFF2_FILE ]]; then
        echo -e "${YELLOW}Skipped: $BASE_NAME (already exists as $WOFF2_FILE)${RESET}"
        echo "Skipped: $BASE_NAME -> $WOFF2_FILE (already exists)" >> "$LOG_FILE"
        continue
    fi

    # Convert using woff2_compress
    woff2_compress "$TTF_FILE"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Converted: $BASE_NAME to $WOFF2_FILE${RESET}"
        echo "Converted: $BASE_NAME -> $WOFF2_FILE" >> "$LOG_FILE"
    else
        echo -e "${RED}Failed to convert: $BASE_NAME${RESET}"
        echo "Failed: $BASE_NAME" >> "$LOG_FILE"
    fi

    # Update progress bar
    ((COUNT++))
    progress_bar $COUNT $TOTAL_FILES
done <<< "$TTF_FILES"

# Finalize
echo
echo -e "${GREEN}Conversion completed. Log saved to $LOG_FILE.${RESET}"
