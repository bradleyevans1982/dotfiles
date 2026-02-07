#!/bin/bash
# Cycles through Gruvbox accent colors for waybar and hyprland

STATE_FILE="/tmp/gruvbox-accent-index"
COLOR_FILE="/tmp/gruvbox-current-accent"
COLOR_DIM_FILE="/tmp/gruvbox-current-accent-dim"
TEMPLATE="$HOME/.config/waybar/style.css.template"
OUTPUT="$HOME/.config/waybar/style.css"

# Gruvbox colors: name, bright, dim
declare -a COLORS=(
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

    # Read previous colors for replacement
    prev_accent=$(cat "$COLOR_FILE" 2>/dev/null || echo "#8ec07c")
    prev_accent_dim=$(cat "$COLOR_DIM_FILE" 2>/dev/null || echo "#689d6a")

    # Save current theme to file for other scripts to read
    echo "$accent" > "$COLOR_FILE"
    echo "$accent_dim" > "$COLOR_DIM_FILE"

    # Generate CSS from template with single accent
    sed -e "s/{{ACCENT_NAME}}/$name/g" \
        -e "s/{{ACCENT}}/$accent/g" \
        -e "s/{{ACCENT_DIM}}/$accent_dim/g" \
        "$TEMPLATE" > "$OUTPUT"

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

    # All gruvbox accent colors (bright and dim)
    ALL_BRIGHT="#fb4934 #fe8019 #fabd2f #b8bb26 #8ec07c #83a598 #d3869b"
    ALL_DIM="#cc241d #d65d0e #d79921 #98971a #689d6a #458588 #b16286"

    # Update rofi themes - replace ALL accent colors with new
    for rofi_file in "$HOME/.config/rofi/theme.rasi" "$HOME/.config/rofi/package-browser.rasi"; do
        if [[ -f "$rofi_file" ]]; then
            for old in $ALL_BRIGHT; do
                sed -i "s/$old/$accent/gI" "$rofi_file"
            done
            for old in $ALL_DIM; do
                sed -i "s/$old/$accent_dim/gI" "$rofi_file"
            done
        fi
    done

    # Update dunst - replace ALL accent colors with new
    DUNST_CONFIG="$HOME/.config/dunst/dunstrc"
    if [[ -f "$DUNST_CONFIG" ]]; then
        for old in $ALL_BRIGHT; do
            sed -i "s/$old/$accent/gI" "$DUNST_CONFIG"
        done
        for old in $ALL_DIM; do
            sed -i "s/$old/$accent_dim/gI" "$DUNST_CONFIG"
        done
        killall dunst 2>/dev/null
        dunst &>/dev/null &
    fi

    # Update GTK3 theme (Thunar, etc.) - replace ALL accent colors
    GTK_CSS="$HOME/.config/gtk-3.0/gtk.css"
    if [[ -f "$GTK_CSS" ]]; then
        for old in $ALL_BRIGHT; do
            sed -i "s/$old/$accent/gI" "$GTK_CSS"
        done
        for old in $ALL_DIM; do
            sed -i "s/$old/$accent_dim/gI" "$GTK_CSS"
        done
        pkill thunar 2>/dev/null
    fi

    # Update Alacritty - replace ALL accent colors
    ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.toml"
    if [[ -f "$ALACRITTY_CONFIG" ]]; then
        for old in $ALL_BRIGHT; do
            sed -i "s/$old/$accent/gI" "$ALACRITTY_CONFIG"
        done
    fi

    # Update Firefox userChrome.css - replace ALL accent colors
    FIREFOX_CHROME="$HOME/.mozilla/firefox/ln0iwwkx.default-release/chrome/userChrome.css"
    if [[ -f "$FIREFOX_CHROME" ]]; then
        for old in $ALL_BRIGHT; do
            sed -i "s/$old/$accent/gI" "$FIREFOX_CHROME"
        done
        for old in $ALL_DIM; do
            sed -i "s/$old/$accent_dim/gI" "$FIREFOX_CHROME"
        done
    fi

    # Update Starship prompt - replace ALL accent colors
    STARSHIP_CONFIG="$HOME/.config/starship.toml"
    if [[ -f "$STARSHIP_CONFIG" ]]; then
        for old in $ALL_BRIGHT; do
            sed -i "s/$old/$accent/gI" "$STARSHIP_CONFIG"
        done
        for old in $ALL_DIM; do
            sed -i "s/$old/$accent_dim/gI" "$STARSHIP_CONFIG"
        done
    fi

    exit 0
fi

# Default: just output current color for waybar module display
echo "{\"text\": \"●\", \"class\": \"$name\", \"tooltip\": \"Theme: $name\nClick to cycle colors\"}"
