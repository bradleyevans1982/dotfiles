#!/bin/bash
# ── wifi-menu.sh ─────────────────────────────────────────────────────────────
# Rofi-based WiFi manager with password entry support
# Usage: Waybar `network` module :on-click
# Theme: Gruvbox (matches ~/.config/rofi/theme.rasi)
# ─────────────────────────────────────────────────────────────────────────────

# Toggle: if rofi is running, kill it and exit
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

# Rofi theme overrides
THEME_WINDOW="window {width: 380px; height: 420px;}"
THEME_LIST="listview {lines: 12;}"
THEME_ELEM="element-text {horizontal-align: 0;}"
THEME_INPUT="entry {placeholder: \"Search...\";}"

# Check if WiFi is enabled
is_wifi_enabled() {
    nmcli radio wifi | grep -q "enabled"
}

# Get current connection
get_current_ssid() {
    nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2
}

# Get available networks sorted by signal
get_available_networks() {
    nmcli -t -f ssid,signal,security dev wifi list --rescan no 2>/dev/null | \
        grep -v '^:' | sort -t: -k2 -nr | awk -F: '!seen[$1]++' | head -15
}

# Check if network is saved
is_saved_network() {
    nmcli -t -f name connection show | grep -qx "$1"
}

# Get security type for display
get_security_icon() {
    case "$1" in
        *WPA3*) echo "󰒃" ;;
        *WPA2*|*WPA*) echo "󰌾" ;;
        *WEP*) echo "󰌿" ;;
        "--"|"") echo "󰿈" ;;
        *) echo "󰌾" ;;
    esac
}

# Signal strength icon
get_signal_icon() {
    local signal=$1
    if (( signal >= 80 )); then echo "󰤨"
    elif (( signal >= 60 )); then echo "󰤥"
    elif (( signal >= 40 )); then echo "󰤢"
    elif (( signal >= 20 )); then echo "󰤟"
    else echo "󰤯"
    fi
}

# Build main menu
build_menu() {
    local current
    current=$(get_current_ssid)

    # Current connection at top (if any) - highlighted in green
    if [[ -n "$current" ]]; then
        echo "<span color='#8ec07c'>󱚽  $current  ✓</span>"
    fi

    # Available networks
    while IFS=: read -r ssid signal security; do
        [[ -z "$ssid" || "$ssid" == "$current" ]] && continue

        local sig_icon sec_icon saved_mark
        sig_icon=$(get_signal_icon "$signal")
        sec_icon=$(get_security_icon "$security")

        if is_saved_network "$ssid"; then
            saved_mark=" 󰄬"
        else
            saved_mark=""
        fi

        echo "$sig_icon  $ssid  $signal%  $sec_icon$saved_mark"
    done <<< "$(get_available_networks)"

    # Actions at bottom with distinct icons
    echo "󰑓  Rescan"
    echo "󰒓  Settings"

    # Power toggle last
    if is_wifi_enabled; then
        echo "󰖪  WiFi OFF"
    else
        echo "󰖩  WiFi ON"
    fi
}

# Password prompt using rofi
prompt_password() {
    local ssid="$1"
    rofi -dmenu \
        -password \
        -p "󰌾 " \
        -mesg "Enter password for: $ssid" \
        -theme-str "$THEME_WINDOW" \
        -theme-str "listview {enabled: false;}" \
        -theme-str "mainbox {children: [\"message\", \"entry\"];}" \
        -theme-str "message {padding: 12px; background-color: rgba(60, 56, 54, 0.75); text-color: #fabd2f;}" \
        -theme-str "entry {padding: 12px; placeholder: \"Password\";}"
}

# Connect to network
connect_to_network() {
    local ssid="$1"
    local security="$2"

    # Check if saved
    if is_saved_network "$ssid"; then
        notify-send "WiFi" "Connecting to $ssid..." -i network-wireless -t 2000
        if nmcli connection up "$ssid" 2>/dev/null; then
            notify-send "WiFi" "Connected to $ssid" -i network-wireless -t 3000
        else
            notify-send "WiFi" "Failed to connect to $ssid" -i network-wireless-offline -t 3000
        fi
        return
    fi

    # Open network (no security)
    if [[ -z "$security" || "$security" == "--" ]]; then
        notify-send "WiFi" "Connecting to open network $ssid..." -i network-wireless -t 2000
        if nmcli dev wifi connect "$ssid" 2>/dev/null; then
            notify-send "WiFi" "Connected to $ssid" -i network-wireless -t 3000
        else
            notify-send "WiFi" "Failed to connect to $ssid" -i network-wireless-offline -t 3000
        fi
        return
    fi

    # Secured network - prompt for password
    local password
    password=$(prompt_password "$ssid")

    [[ -z "$password" ]] && return

    notify-send "WiFi" "Connecting to $ssid..." -i network-wireless -t 2000

    if nmcli dev wifi connect "$ssid" password "$password" 2>/dev/null; then
        notify-send "WiFi" "Connected to $ssid" -i network-wireless -t 3000
    else
        notify-send "WiFi" "Failed to connect. Check password." -i network-wireless-offline -t 4000
        # Retry
        connect_to_network "$ssid" "$security"
    fi
}

# Parse selection and extract SSID
parse_ssid() {
    local selection="$1"
    # Remove icon prefix (icon + 2 spaces) and everything after SSID (2 spaces + percent)
    echo "$selection" | sed 's/^[^ ]*  //' | sed 's/  [0-9]*%.*//'
}

# Get security type for SSID
get_network_security() {
    local ssid="$1"
    nmcli -t -f ssid,security dev wifi list --rescan no 2>/dev/null | \
        grep "^${ssid}:" | head -1 | cut -d: -f2
}

# Handle menu selection
handle_selection() {
    local selection="$1"

    case "$selection" in
        "󰖩  WiFi ON")
            nmcli radio wifi on
            notify-send "WiFi" "WiFi enabled" -i network-wireless -t 2000
            sleep 2
            exec "$0"
            ;;
        "󰖪  WiFi OFF")
            nmcli radio wifi off
            notify-send "WiFi" "WiFi disabled" -i network-wireless-offline -t 2000
            ;;
        "")
            return
            ;;
        *"󱚽  "*)
            # Currently connected - disconnect (strip pango markup)
            local ssid
            ssid=$(echo "$selection" | sed 's/<[^>]*>//g')
            ssid="${ssid#󱚽  }"
            ssid="${ssid%  ✓}"
            nmcli connection down "$ssid" 2>/dev/null
            notify-send "WiFi" "Disconnected from $ssid" -i network-wireless-offline -t 2000
            sleep 1
            exec "$0"
            ;;
        "󰑓  Rescan")
            notify-send "WiFi" "Scanning..." -i network-wireless -t 1500
            nmcli dev wifi rescan 2>/dev/null
            sleep 2
            exec "$0"
            ;;
        "󰒓  Settings")
            alacritty --title "Network Settings" -e bash -c '
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
                nmtui
            ' &
            ;;
        "󰤨  "*|"󰤥  "*|"󰤢  "*|"󰤟  "*|"󰤯  "*)
            # Network item - connect
            local ssid security
            ssid=$(parse_ssid "$selection")
            security=$(get_network_security "$ssid")
            connect_to_network "$ssid" "$security"
            ;;
    esac
}

# Main
main() {
    local menu selected
    menu=$(build_menu)

    selected=$(echo -e "$menu" | rofi -dmenu \
        -p "󰖩 " \
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
