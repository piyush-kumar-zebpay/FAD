#!/bin/bash
# Menu Selection Demo Script
# Standalone menu functions for testing

# Colors
MAGENTA='\033[35m'
BLUE='\033[34m'
CYAN='\033[36m'
WHITE='\033[97m'
DARK_GRAY='\033[90m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Unicode characters
STAR='✦'
FILLED='●'
EMPTY='○'
DIAMOND_FILLED='◆'
DIAMOND_EMPTY='◇'
CHECK='✓'
ARROW='›'

show_banner() {
    echo ""
    echo -e "  ${MAGENTA}${STAR}${RESET} ${BLUE}Menu${RESET} ${CYAN}Selection ${MAGENTA}Demo${RESET}"
    echo ""
}

# Read a single key press
read_key() {
    local key
    IFS= read -rsn1 key
    
    # Check for escape sequence (arrow keys)
    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key
        case "$key" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            '[C') echo "RIGHT" ;;
            '[D') echo "LEFT" ;;
            *) echo "ESC" ;;
        esac
    elif [[ "$key" == "" ]]; then
        echo "ENTER"
    elif [[ "$key" == " " ]]; then
        echo "SPACE"
    else
        echo "$key"
    fi
}

show_single_select_menu() {
    local title="$1"
    local prev_info="$2"
    shift 2
    local options=("$@")
    local selected_index=0
    local options_count=${#options[@]}
    
    # Hide cursor
    tput civis
    
    while true; do
        clear
        show_banner
        
        if [ -n "$prev_info" ]; then
            echo -e "$prev_info"
            echo ""
        fi
        
        echo -e "  ${WHITE}$title${RESET}"
        echo -e "  ${DARK_GRAY}Use ${CYAN}arrows${DARK_GRAY} to navigate, ${CYAN}Enter${DARK_GRAY} to select${RESET}"
        echo ""
        
        for i in "${!options[@]}"; do
            if [ $i -eq $selected_index ]; then
                echo -e "    ${MAGENTA}${FILLED}${RESET} ${WHITE}${options[$i]}${RESET}"
            else
                echo -e "    ${DARK_GRAY}${EMPTY} ${options[$i]}${RESET}"
            fi
        done
        
        local key=$(read_key)
        
        case "$key" in
            "UP")
                ((selected_index--))
                if [ $selected_index -lt 0 ]; then
                    selected_index=$((options_count - 1))
                fi
                ;;
            "DOWN")
                ((selected_index++))
                if [ $selected_index -ge $options_count ]; then
                    selected_index=0
                fi
                ;;
            "ENTER")
                tput cnorm  # Show cursor
                MENU_RESULT="${options[$selected_index]}"
                return
                ;;
        esac
    done
}

show_multi_select_menu() {
    local title="$1"
    local prev_info="$2"
    shift 2
    local options=("$@")
    local selected_index=0
    local options_count=${#options[@]}
    
    # Initialize selection array (first option selected by default)
    declare -a selected
    for i in "${!options[@]}"; do
        if [ $i -eq 0 ]; then
            selected[$i]=1
        else
            selected[$i]=0
        fi
    done
    
    # Hide cursor
    tput civis
    
    while true; do
        clear
        show_banner
        
        if [ -n "$prev_info" ]; then
            echo -e "$prev_info"
            echo ""
        fi
        
        echo -e "  ${WHITE}$title${RESET}"
        echo -e "  ${DARK_GRAY}Use ${CYAN}arrows${DARK_GRAY} to navigate, ${CYAN}Space${DARK_GRAY} to toggle, ${CYAN}Enter${DARK_GRAY} to confirm${RESET}"
        echo ""
        
        for i in "${!options[@]}"; do
            local checkbox
            local check_color
            
            if [ ${selected[$i]} -eq 1 ]; then
                checkbox="$DIAMOND_FILLED"
                check_color="$MAGENTA"
            else
                checkbox="$DIAMOND_EMPTY"
                check_color="$DARK_GRAY"
            fi
            
            if [ $i -eq $selected_index ]; then
                echo -e "    ${check_color}${checkbox}${RESET} ${WHITE}${options[$i]}${RESET}"
            else
                echo -e "    ${check_color}${checkbox}${RESET} ${DARK_GRAY}${options[$i]}${RESET}"
            fi
        done
        
        local key=$(read_key)
        
        case "$key" in
            "UP")
                ((selected_index--))
                if [ $selected_index -lt 0 ]; then
                    selected_index=$((options_count - 1))
                fi
                ;;
            "DOWN")
                ((selected_index++))
                if [ $selected_index -ge $options_count ]; then
                    selected_index=0
                fi
                ;;
            "SPACE")
                if [ ${selected[$selected_index]} -eq 1 ]; then
                    selected[$selected_index]=0
                else
                    selected[$selected_index]=1
                fi
                ;;
            "ENTER")
                tput cnorm  # Show cursor
                
                # Build result string
                local result=""
                for i in "${!options[@]}"; do
                    if [ ${selected[$i]} -eq 1 ]; then
                        if [ -n "$result" ]; then
                            result="$result, ${options[$i]}"
                        else
                            result="${options[$i]}"
                        fi
                    fi
                done
                
                # Default to first option if nothing selected
                if [ -z "$result" ]; then
                    result="${options[0]}"
                fi
                
                MENU_RESULT="$result"
                return
                ;;
        esac
    done
}

show_confirm_menu() {
    local summary="$1"
    local selected_index=0
    
    # Hide cursor
    tput civis
    
    while true; do
        clear
        show_banner
        
        echo -e "  ${DARK_GRAY}----------------------------------------${RESET}"
        echo -e "  ${WHITE}Summary${RESET}"
        echo -e "  ${DARK_GRAY}----------------------------------------${RESET}"
        echo ""
        echo -e "$summary"
        echo ""
        echo -e "  ${DARK_GRAY}----------------------------------------${RESET}"
        echo ""
        echo -e "  ${WHITE}Do you want to proceed?${RESET}"
        echo ""
        
        if [ $selected_index -eq 0 ]; then
            echo -e "    ${MAGENTA}${FILLED}${RESET} ${WHITE}Yes${RESET}     ${DARK_GRAY}${EMPTY} No${RESET}"
        else
            echo -e "    ${DARK_GRAY}${EMPTY} Yes${RESET}     ${MAGENTA}${FILLED}${RESET} ${WHITE}No${RESET}"
        fi
        
        local key=$(read_key)
        
        case "$key" in
            "LEFT")
                selected_index=0
                ;;
            "RIGHT")
                selected_index=1
                ;;
            "UP"|"DOWN")
                selected_index=$((1 - selected_index))
                ;;
            "ENTER")
                tput cnorm  # Show cursor
                if [ $selected_index -eq 0 ]; then
                    MENU_RESULT="yes"
                else
                    MENU_RESULT="no"
                fi
                return
                ;;
        esac
    done
}

show_text_input() {
    local prompt="$1"
    local default_value="$2"
    local prev_info="$3"
    
    clear
    show_banner
    
    if [ -n "$prev_info" ]; then
        echo -e "$prev_info"
        echo ""
    fi
    
    echo -e "  ${WHITE}$prompt${RESET}"
    echo -e "  ${DARK_GRAY}Press ${CYAN}Enter${DARK_GRAY} for default${RESET}"
    echo ""
    
    echo -e -n "    ${MAGENTA}${ARROW}${RESET} "
    read -r user_input
    
    if [ -z "$user_input" ]; then
        MENU_RESULT="$default_value"
    else
        MENU_RESULT="$user_input"
    fi
}

# Cleanup function to restore cursor on exit
cleanup() {
    tput cnorm 2>/dev/null
}
trap cleanup EXIT

# =============================================
# DEMO - Test all menu types
# =============================================

# Demo 1: Single Select
show_single_select_menu "Select your favorite color" "" "Red" "Green" "Blue" "Yellow" "Purple"
color="$MENU_RESULT"
info1="  ${GREEN}${CHECK}${RESET} Color: $color"

# Demo 2: Text Input
show_text_input "Enter your name" "Anonymous" "$info1"
name="$MENU_RESULT"
info2="${info1}\n  ${GREEN}${CHECK}${RESET} Name: $name"

# Demo 3: Multi Select
show_multi_select_menu "Select your hobbies" "$info2" "Reading" "Gaming" "Coding" "Music" "Sports"
hobbies="$MENU_RESULT"

# Demo 4: Confirmation
summary="    Color    $color
    Name     $name
    Hobbies  $hobbies"

show_confirm_menu "$summary"
confirmed="$MENU_RESULT"

# Show final result
clear
show_banner
echo -e "  ${DARK_GRAY}----------------------------------------${RESET}"
echo -e "  ${WHITE}Final Results${RESET}"
echo -e "  ${DARK_GRAY}----------------------------------------${RESET}"
echo ""
echo -e "  ${GREEN}${CHECK}${RESET} Color: $color"
echo -e "  ${GREEN}${CHECK}${RESET} Name: $name"
echo -e "  ${GREEN}${CHECK}${RESET} Hobbies: $hobbies"
echo -e "  ${GREEN}${CHECK}${RESET} Confirmed: $confirmed"
echo ""
echo -e "  ${MAGENTA}${STAR}${RESET} ${WHITE}Demo complete!${RESET}"
echo ""
