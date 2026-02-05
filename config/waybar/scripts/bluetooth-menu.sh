#!/bin/bash
# ── bluetooth-menu.sh ────────────────────────────────────────────────────────
# Rofi-based Bluetooth manager
# Usage: Waybar `bluetooth` module :on-click
# Theme: Gruvbox (matches ~/.config/rofi/theme.rasi)
# ─────────────────────────────────────────────────────────────────────────────

# Toggle: if rofi is running, kill it and exit
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

# Rofi theme overrides (match wifi-menu.sh)
THEME_WINDOW="window {width: 380px; height: 420px;}"
THEME_LIST="listview {lines: 12;}"
THEME_ELEM="element-text {horizontal-align: 0;}"
THEME_INPUT="entry {placeholder: \"Search...\";}"

# Check if Bluetooth is blocked
is_blocked() {
    rfkill list bluetooth | grep -q "Soft blocked: yes"
}

# Check if Bluetooth service is powered on
is_powered() {
    bluetoothctl show | grep -q "Powered: yes"
}

# Get paired devices: "MAC Name"
get_paired_devices() {
    bluetoothctl devices Paired 2>/dev/null | sed 's/Device //'
}

# Check if a device is connected
is_connected() {
    bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"
}

# Get device MAC by name
get_mac_by_name() {
    local name="$1"
    get_paired_devices | while read -r mac device_name; do
        if [[ "$device_name" == "$name" ]]; then
            echo "$mac"
            return
        fi
    done
}

# Build menu
build_menu() {
    # Connected devices first
    if ! is_blocked && is_powered; then
        while read -r mac name; do
            [[ -z "$mac" ]] && continue
            if is_connected "$mac"; then
                echo "<span color='#8ec07c'>󰂱  $name  ✓</span>"
            fi
        done <<< "$(get_paired_devices)"

        # Then disconnected paired devices
        while read -r mac name; do
            [[ -z "$mac" ]] && continue
            if ! is_connected "$mac"; then
                echo "󰂰  $name"
            fi
        done <<< "$(get_paired_devices)"
    fi

    # Actions
    echo "󰑐  Scan"
    echo "󰒓  Settings"

    # Power toggle
    if is_blocked || ! is_powered; then
        echo "󰂯  Bluetooth ON"
    else
        echo "󰂲  Bluetooth OFF"
    fi
}

# Handle selection
handle_selection() {
    case "$1" in
        "󰂯  Bluetooth ON")
            rfkill unblock bluetooth
            sleep 0.5
            bluetoothctl power on
            notify-send "Bluetooth" "Bluetooth enabled" -i bluetooth -t 2000
            sleep 1
            exec "$0"
            ;;
        "󰂲  Bluetooth OFF")
            bluetoothctl power off
            sleep 0.3
            rfkill block bluetooth
            notify-send "Bluetooth" "Bluetooth disabled" -i bluetooth -t 2000
            ;;
        "")
            return
            ;;
        *"󰂱  "*)
            # Connected device - disconnect (strip pango markup)
            local name
            name=$(echo "$1" | sed 's/<[^>]*>//g')
            name="${name#󰂱  }"
            name="${name%  ✓}"
            local mac
            mac=$(get_mac_by_name "$name")
            if [[ -n "$mac" ]]; then
                bluetoothctl disconnect "$mac"
                notify-send "Bluetooth" "Disconnected from $name" -i bluetooth -t 2000
                sleep 1
                exec "$0"
            fi
            ;;
        "󰂰  "*)
            # Disconnected device - connect
            local name="${1#󰂰  }"
            local mac
            mac=$(get_mac_by_name "$name")
            if [[ -n "$mac" ]]; then
                notify-send "Bluetooth" "Connecting to $name..." -i bluetooth -t 2000
                bluetoothctl connect "$mac"
                sleep 2
                exec "$0"
            fi
            ;;
        "󰑐  Scan")
            notify-send "Bluetooth" "Scanning for devices..." -i bluetooth -t 2000
            alacritty --title "Bluetooth Scan" -e bash -c '
                export NEWT_COLORS="
                    root=,rgba(40, 40, 40, 0.75)
                    window=#ebdbb2,rgba(40, 40, 40, 0.75)
                    border=#d79921,rgba(40, 40, 40, 0.75)
                    title=#fabd2f,rgba(40, 40, 40, 0.75)
                    button=rgba(40, 40, 40, 0.75),#d79921
                    actbutton=rgba(40, 40, 40, 0.75),#fabd2f
                    checkbox=#ebdbb2,rgba(40, 40, 40, 0.75)
                    actcheckbox=#fabd2f,rgba(60, 56, 54, 0.75)
                    entry=#ebdbb2,rgba(60, 56, 54, 0.75)
                    label=#ebdbb2,rgba(40, 40, 40, 0.75)
                    listbox=#ebdbb2,rgba(40, 40, 40, 0.75)
                    actlistbox=rgba(40, 40, 40, 0.75),#d79921
                    sellistbox=#fabd2f,rgba(60, 56, 54, 0.75)
                    textbox=#ebdbb2,rgba(40, 40, 40, 0.75)
                    acttextbox=#fabd2f,rgba(60, 56, 54, 0.75)
                    helpline=#928374,rgba(40, 40, 40, 0.75)
                    roottext=#ebdbb2,rgba(40, 40, 40, 0.75)
                "
                echo -e "\033[1;33mScanning for Bluetooth devices...\033[0m"
                echo ""
                bluetoothctl --timeout 10 scan on &
                sleep 10
                echo ""
                echo -e "\033[1;33mAvailable devices:\033[0m"
                bluetoothctl devices
                echo ""
                echo -e "\033[0;90mPress Enter to close\033[0m"
                read
            ' &
            ;;
        "󰒓  Settings")
            blueman-manager &
            ;;
    esac
}

# Main
main() {
    local menu selected
    menu=$(build_menu)

    selected=$(echo -e "$menu" | rofi -dmenu \
        -p "󰂯 " \
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
