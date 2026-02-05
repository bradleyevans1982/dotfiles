#!/bin/bash
# ── powermenu.sh ─────────────────────────────────────────────────────────────
# Rofi-based power menu
# Usage: Waybar `custom/power` module :on-click
# Theme: Gruvbox (matches ~/.config/rofi/theme.rasi)
# ─────────────────────────────────────────────────────────────────────────────

# Toggle: if rofi is running, kill it and exit
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

# Rofi theme overrides (match wifi-menu.sh)
THEME_WINDOW="window {width: 340px; height: 540px;}"
THEME_LIST="listview {lines: 10;}"
THEME_ELEM="element-text {horizontal-align: 0;}"
THEME_INPUT="entry {enabled: false;}"

# Get current power profile
get_power_profile() {
    cat /sys/firmware/acpi/platform_profile 2>/dev/null
}

build_menu() {
    local profile=$(get_power_profile)

    # Power profiles with current highlighted
    case "$profile" in
        "low-power")
            echo "<span color='#fabd2f'>󰌪  Power Saver ON</span>"
            echo "󰗑  Balanced"
            echo "󰓅  Performance"
            ;;
        "performance")
            echo "󰌪  Power Saver"
            echo "󰗑  Balanced"
            echo "<span color='#fe8019'>󰓅  Performance ON</span>"
            ;;
        *)
            echo "󰌪  Power Saver"
            echo "<span color='#8ec07c'>󰗑  Balanced ON</span>"
            echo "󰓅  Performance"
            ;;
    esac

    # System actions
    echo "󰌾  Lock"
    echo "󰤄  Suspend"
    echo "󰍃  Logout"
    echo "󰜉  Reboot"
    echo "󰐥  Shutdown"
}

menu=$(build_menu)

# Show menu
selected=$(echo -e "$menu" | rofi -dmenu \
    -p "󰐥 " \
    -i \
    -markup-rows \
    -click-to-exit \
    -theme-str "$THEME_WINDOW" \
    -theme-str "$THEME_LIST" \
    -theme-str "$THEME_ELEM" \
    -theme-str "$THEME_INPUT")

# Handle selection
case "$selected" in
    *"Power Saver"*)
        echo "low-power" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
        notify-send "Power Profile" "Power Saver enabled" -t 2000
        ;;
    *"Balanced"*)
        echo "balanced" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
        notify-send "Power Profile" "Balanced mode" -t 2000
        ;;
    *"Performance"*)
        echo "performance" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
        notify-send "Power Profile" "Performance mode enabled" -t 2000
        ;;
    "󰌾  Lock")
        ~/.config/hypr/scripts/lock.sh 2>/dev/null || hyprlock
        ;;
    "󰤄  Suspend")
        systemctl suspend
        ;;
    "󰍃  Logout")
        hyprctl dispatch exit
        ;;
    "󰜉  Reboot")
        systemctl reboot
        ;;
    "󰐥  Shutdown")
        systemctl poweroff
        ;;
esac
