#!/bin/bash

# Define your options
options="Shutdown\nReboot\nLock\nSuspend\nLogout"

# Show the rofi menu
# -dmenu: Tells rofi to read from stdin (the options we're piping in)
# -p "Power": Sets the prompt text
chosen=$(echo -e "$options" | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Power Menu")

# Run the command based on the choice
case "$chosen" in
    "Shutdown")
        systemctl poweroff
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Lock")
        # Use hyprlock or swaylock, whichever you have
        hyprlock
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Logout")
        hyprctl dispatch exit
        ;;
esac
