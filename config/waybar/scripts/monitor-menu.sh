#!/bin/bash
# ── monitor-menu.sh ─────────────────────────────────────────────────────────
# Rofi-based monitor management menu
# Usage: Waybar custom module :on-click
# Theme: Gruvbox (matches existing waybar scripts)
# ─────────────────────────────────────────────────────────────────────────────

# Toggle: if rofi is running, kill it and exit
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

# Rofi theme overrides
THEME_WINDOW="window {width: 420px; height: 400px;}"
THEME_LIST="listview {lines: 10;}"
THEME_ELEM="element-text {horizontal-align: 0;}"
THEME_INPUT="entry {enabled: false;}"

# Get ALL monitors including disabled
get_all_monitors() {
    hyprctl monitors all -j
}

# Get transform name from number
transform_name() {
    case "$1" in
        0) echo "Normal" ;;
        1) echo "90°" ;;
        2) echo "180°" ;;
        3) echo "270°" ;;
        4) echo "Flipped" ;;
        5) echo "Flipped 90°" ;;
        6) echo "Flipped 180°" ;;
        7) echo "Flipped 270°" ;;
        *) echo "Normal" ;;
    esac
}

# Strip markup helper
strip_markup() {
    echo "$1" | sed 's/<[^>]*>//g'
}

# Build main menu
build_menu() {
    local monitors=$(get_all_monitors)
    local count=$(echo "$monitors" | jq length)

    echo "<span color='#fabd2f'>󰍹  Monitor Settings</span>"
    echo "─────────────────────"

    for i in $(seq 0 $((count - 1))); do
        local name=$(echo "$monitors" | jq -r ".[$i].name")
        local res=$(echo "$monitors" | jq -r ".[$i].width")x$(echo "$monitors" | jq -r ".[$i].height")
        local transform=$(echo "$monitors" | jq -r ".[$i].transform")
        local rot=$(transform_name "$transform")
        local disabled=$(echo "$monitors" | jq -r ".[$i].disabled")
        local x=$(echo "$monitors" | jq -r ".[$i].x")
        local y=$(echo "$monitors" | jq -r ".[$i].y")

        if [ "$disabled" = "true" ]; then
            echo "<span color='#928374'>  󰶐  $name (disabled)</span>"
        else
            echo "<span color='#8ec07c'>  󰍹  $name - $res [$rot] @${x},${y}</span>"
        fi
    done

    echo "─────────────────────"
    echo "<span color='#83a598'>󰔎  Open Visual Editor</span>"
}


# Show rofi menu
show_menu() {
    build_menu | rofi -dmenu \
        -p "󰍹 " \
        -i \
        -markup-rows \
        -click-to-exit \
        -theme-str "$THEME_WINDOW" \
        -theme-str "$THEME_LIST" \
        -theme-str "$THEME_ELEM" \
        -theme-str "$THEME_INPUT"
}

# ── MAIN ────────────────────────────────────────────────────────────────────

main() {
    while true; do
        local selected=$(show_menu)
        [ -z "$selected" ] && exit 0

        local clean=$(strip_markup "$selected" | xargs)

        case "$clean" in
            *"Open Visual Editor"*)
                ~/.config/hypr/scripts/monitor-manager.py &
                exit 0
                ;;
            *)
                # Ignore all other clicks (monitor info lines, separators, etc.)
                continue
                ;;
        esac
    done
}

main
