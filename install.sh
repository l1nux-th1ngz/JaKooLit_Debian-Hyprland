#!/bin/bash

echo "all credit belongs to JaKoolLit @ https://github.com/JaKooLit""


# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting..."
    exit 1
fi

clear

# Welcome message
echo
echo "$(tput setaf 166)ATTENTION: Run a full system update and Reboot first!! (Highly Recommended)$(tput sgr0)"
echo
echo "$(tput setaf 3)NOTE: You will be required to answer some questions during the installation!$(tput sgr0)"
echo
echo "$(tput setaf 3)NOTE: If you are installing on a VM, ensure to enable 3D acceleration else Hyprland won't start!$(tput sgr0)"
echo

printf "\n%.0s" {1..5}
echo "$(tput bold)$(tput setaf 3)ATTENTION!!!! VERY IMPORTANT NOTICE!!!!$(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)Recent Hyprland release v0.33.0 needed a newer libdrm. Debian doesn't have it yet. Installing v0.32.3 as fallback.$(tput sgr0)"
printf "\n%.0s" {1..3}

# Ask user if they want to proceed
read -p "$(tput setaf 6)Would you like to proceed? (y/n): $(tput sgr0)" proceed
if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
    echo "Installation aborted."
    exit 1
fi

# Confirm sources.list edit
read -p "$(tput setaf 6)Have you edited your /etc/apt/sources.list? (y/n): $(tput sgr0)" proceed2
if [[ "$proceed2" != "y" && "$proceed2" != "Y" ]]; then
    echo "Installation aborted. Kindly edit your sources.list first. Refer to readme."
    exit 1
fi

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
WARN="$(tput setaf 166)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
ORANGE=$(tput setaf 166)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Function to colorize prompts
colorize_prompt() {
    local color="$1"
    local message="$2"
    echo -n "${color}${message}$(tput sgr0)"
}

# Set the name of the log file to include the current date and time
LOG="install-$(date +%d-%H%M%S).log"

# Initialize variables to store user responses
bluetooth=""
dots=""
gtk_themes=""
sddm=""
swaylock=""
xdph=""
zsh=""

# Directory where scripts are located
script_directory=install-scripts

# Function to ask a yes/no question
ask_yes_no() {
    local prompt="$1"
    local response_var="$2"
    while true; do
        read -p "$(colorize_prompt "$CAT" "$prompt (y/n): ")" choice
        case "$choice" in
            [Yy]*) eval "$response_var='Y'"; break ;;
            [Nn]*) eval "$response_var='N'"; break ;;
            *) echo "Please answer with y or n." ;;
        esac
    done
}

# Function to execute a script if it exists
execute_script() {
    local script="$1"
    local script_path="$script_directory/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        "$script_path"
    else
        echo "$script not found in $script_directory."
    fi
}

# Collect user responses
echo
ask_yes_no "-Install GTK themes (required for Dark/Light function)?" gtk_themes
echo
ask_yes_no "-Do you want to configure Bluetooth?" bluetooth
echo
ask_yes_no "-Install & configure SDDM log-in Manager plus (OPTIONAL) SDDM Theme?" sddm
echo
ask_yes_no "-Install XDG-DESKTOP-PORTAL-HYPRLAND? (For proper Screen Share ie OBS)" xdph
echo
ask_yes_no "-Install zsh & oh-my-zsh plus (OPTIONAL) pokemon-colorscripts for tty?" zsh
echo
ask_yes_no "-Install swaylock-effects? (recommended - for screen locks)" swaylock
echo
ask_yes_no "-Do you want to download and install pre-configured Hyprland-dotfiles?" dots
echo

# Make all scripts executable
chmod +x "$script_directory"/*

# Update system repositories
echo "${NOTE} Updating system repositories..."
sudo apt update | tee -a "$LOG"

# Run main scripts
execute_script "00-dependencies.sh"
execute_script "00-hypr-pkgs.sh"
execute_script "fonts.sh"
execute_script "swappy.sh"
execute_script "swww.sh"
execute_script "rofi-wayland.sh"
execute_script "pywal.sh"
execute_script "force-install.sh"
execute_script "hyprlang.sh"

# Optional scripts based on user choices
if [ "$nvidia" == "Y" ]; then
    execute_script "nvidia.sh"
fi

if [ "$nvidia" == "N" ]; then
    execute_script "hyprland.sh"
fi

if [ "$gtk_themes" == "Y" ]; then
    execute_script "gtk_themes.sh"
fi

if [ "$bluetooth" == "Y" ]; then
    execute_script "bluetooth.sh"
fi

if [ "$sddm" == "Y" ]; then
    execute_script "sddm.sh"
fi

if [ "$xdph" == "Y" ]; then
    execute_script "xdph.sh"
fi

if [ "$zsh" == "Y" ]; then
    execute_script "zsh.sh"
fi

if [ "$swaylock" == "Y" ]; then
    execute_script "swaylock-effects.sh"
fi

execute_script "InputGroup.sh"

if [ "$dots" == "Y" ]; then
    execute_script "dotfiles.sh"
fi

# Cleanup
echo "${OK} performing some clean up."
if [ -e "JetBrainsMono.tar.xz" ]; then
    echo "JetBrainsMono.tar.xz found. Deleting..."
    rm JetBrainsMono.tar.xz
    echo "JetBrainsMono.tar.xz deleted successfully."
fi

# Final messages
clear
echo "${OK} Yey! Installation Completed."
echo
echo "${NOTE} You can start Hyprland by typing 'Hyprland' (note the capital H!)."
echo
echo "${NOTE} It is highly recommended to reboot your system."
echo

# Reboot prompt
read -rp "${CAT} Would you like to reboot now? (y/n): " HYP
if [[ "$HYP" =~ ^[Yy]$ ]]; then
    if [[ "$nvidia" == "Y" ]]; then
        echo "${NOTE} NVIDIA GPU detected. Rebooting the system..."
        systemctl reboot
    else
        systemctl reboot
    fi
fi
