#!/bin/bash
# ── quick-actions.sh ─────────────────────────────────────────────────────────
# Rofi quick actions menu for screenshots, night light, wallpaper
# ─────────────────────────────────────────────────────────────────────────────

# Toggle: if rofi is running, kill it and exit
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

THEME_WINDOW="window {width: 480px; height: 560px;}"
THEME_LIST="listview {lines: 9;}"
THEME_ELEM="element-text {horizontal-align: 0;}"
THEME_INPUT="entry {placeholder: \"Action...\";}"

# Check if hyprsunset is running
is_nightlight_on() {
    pgrep -x hyprsunset > /dev/null
}

build_menu() {
    echo "󰹑  Screenshot Region (Clipboard)"
    echo "󰹑  Screenshot Region (Save)"
    echo "󱣴  Screenshot Window"
    echo "󰍹  Screenshot Monitor"
    if is_nightlight_on; then
        echo "<span color='#8ec07c'>󰖨  Night Light ON</span>"
    else
        echo "󰖨  Night Light OFF"
    fi
    echo "󰸉  Random Wallpaper"
    echo "─────────────────────"
    echo "󰍹  Monitor Settings"
}

handle_selection() {
    case "$1" in
        "󰹑  Screenshot Region (Clipboard)")
            hyprshot -m region --clipboard-only
            ;;
        "󰹑  Screenshot Region (Save)")
            hyprshot -m region -o ~/Pictures
            notify-send "Screenshot" "Saved to ~/Pictures" -t 2000
            ;;
        "󱣴  Screenshot Window")
            hyprshot -m window --clipboard-only
            ;;
        "󰍹  Screenshot Monitor")
            hyprshot -m output -o ~/Pictures
            notify-send "Screenshot" "Saved to ~/Pictures" -t 2000
            ;;
        *"Night Light ON"*)
            pkill hyprsunset
            notify-send "Night Light" "Disabled" -t 2000
            ;;
        *"Night Light OFF"*)
            hyprsunset -t 4500 &
            notify-send "Night Light" "Enabled (4500K)" -t 2000
            ;;
        "󰸉  Random Wallpaper")
            ~/.config/hypr/scripts/random-wallpaper.sh
            notify-send "Wallpaper" "Changed" -t 2000
            ;;
        "󰍹  Monitor Settings")
            ~/.config/waybar/scripts/monitor-menu.sh
            ;;
    esac
}

main() {
    local menu selected
    menu=$(build_menu)

    selected=$(echo -e "$menu" | rofi -dmenu \
        -p "󰀻 " \
        -i \
        -markup-rows \
        -click-to-exit \
        -theme-str "$THEME_WINDOW" \
        -theme-str "$THEME_LIST" \
        -theme-str "$THEME_ELEM" \
        -theme-str "$THEME_INPUT")

    [[ -n "$selected" ]] && handle_selection "$selected"
}

main
