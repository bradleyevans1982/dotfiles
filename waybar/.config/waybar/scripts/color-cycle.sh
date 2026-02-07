#!/bin/bash
# Cycles through Gruvbox accent colors for waybar and hyprland

STATE_FILE="/tmp/gruvbox-accent-index"
COLOR_FILE="/tmp/gruvbox-current-accent"
TEMPLATE="$HOME/.config/waybar/style.css.template"
ORIGINAL="$HOME/.config/waybar/style.css.original"
OUTPUT="$HOME/.config/waybar/style.css"

# Gruvbox colors: name, bright, dim (first entry is "original" - uses saved file)
declare -a COLORS=(
    "original|#fabd2f|#d79921"
    "red|#fb4934|#cc241d"
    "orange|#fe8019|#d65d0e"
    "yellow|#fabd2f|#d79921"
    "green|#b8bb26|#98971a"
    "aqua|#8ec07c|#689d6a"
    "blue|#83a598|#458588"
    "purple|#d3869b|#b16286"
)

# Get current index or start at 0
if [[ -f "$STATE_FILE" ]]; then
    index=$(cat "$STATE_FILE")
else
    index=0
fi

# Parse current color
IFS='|' read -r name accent accent_dim <<< "${COLORS[$index]}"

# Check if called with --apply flag (actually apply the theme)
if [[ "$1" == "--apply" ]]; then
    # Increment to next color
    index=$(( (index + 1) % ${#COLORS[@]} ))
    echo "$index" > "$STATE_FILE"

    # Parse new color
    IFS='|' read -r name accent accent_dim <<< "${COLORS[$index]}"

    # Save current theme to file for other scripts to read
    # For "original" write the name, for others write the hex color
    if [[ "$name" == "original" ]]; then
        echo "original" > "$COLOR_FILE"
    else
        echo "$accent" > "$COLOR_FILE"
    fi

    if [[ "$name" == "original" ]]; then
        # Use the original multi-color theme
        cp "$ORIGINAL" "$OUTPUT"
    else
        # Generate CSS from template with single accent
        sed -e "s/{{ACCENT_NAME}}/$name/g" \
            -e "s/{{ACCENT}}/$accent/g" \
            -e "s/{{ACCENT_DIM}}/$accent_dim/g" \
            "$TEMPLATE" > "$OUTPUT"
    fi

    # Reload waybar
    killall waybar 2>/dev/null
    sleep 0.2
    hyprctl dispatch exec waybar >/dev/null 2>&1

    # Update hyprland colors (rgba format)
    hypr_accent="${accent/#\#/}"
    hypr_accent_dim="${accent_dim/#\#/}"
    hyprctl keyword general:col.active_border "rgba(${hypr_accent}ff)" >/dev/null 2>&1
    hyprctl keyword general:col.inactive_border "rgba(${hypr_accent_dim}88)" >/dev/null 2>&1
    hyprctl keyword decoration:shadow:color "rgba(${hypr_accent_dim}ee)" >/dev/null 2>&1

    exit 0
fi

# Default: just output current color for waybar module display
echo "{\"text\": \"●\", \"class\": \"$name\", \"tooltip\": \"Theme: $name\nClick to cycle colors\"}"
