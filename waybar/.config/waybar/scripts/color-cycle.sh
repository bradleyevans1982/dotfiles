#!/bin/bash
# Cycles through Gruvbox accent colors for waybar and hyprland

STATE_FILE="/tmp/gruvbox-accent-index"
COLOR_FILE="/tmp/gruvbox-current-accent"
COLOR_DIM_FILE="/tmp/gruvbox-current-accent-dim"
TEMPLATE="$HOME/.config/waybar/style.css.template"
OUTPUT="$HOME/.config/waybar/style.css"

# Gruvbox colors: name, bright, dim
# Pastel/muted palette matching the soft blue aesthetic
declare -a COLORS=(
    "mauve|#a898b8|#887898"
    "peach|#d4a373|#b48353"
    "brick|#c08070|#a06050"
    "straw|#c8b878|#a89858"
    "mint|#8ec07c|#689d6a"
    "amber|#c89070|#a87050"
    "teal|#70a8a8|#508888"
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

    # All accent colors (bright and dim) - pastel palette + old gruvbox for compatibility
    ALL_BRIGHT="#a898b8 #d4a373 #c08070 #c8b878 #8ec07c #c89070 #70a8a8 #fb4934 #fe8019 #fabd2f #b8bb26 #83a598 #d3869b #d4c4a1 #d4a0a0 #c4a7c7 #a9b665"
    ALL_DIM="#887898 #b48353 #a06050 #a89858 #689d6a #a87050 #508888 #cc241d #d65d0e #d79921 #98971a #458588 #b16286 #b4a481 #b48080 #a487a7 #899646"

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

        # Also replace RGB values in rgba() for box-shadow (dim colors)
        # Includes new pastel + old gruvbox for compatibility
        declare -a RGB_DIM=(
            "136, 120, 152"  # mauve dim
            "180, 131, 83"   # peach dim
            "160, 96, 80"    # brick dim
            "168, 152, 88"   # straw dim
            "104, 157, 106"  # mint dim
            "168, 112, 80"   # amber dim
            "80, 136, 136"   # teal dim
            "204, 36, 29"    # old red dim
            "214, 93, 14"    # old orange dim
            "215, 153, 33"   # old yellow dim
            "152, 151, 26"   # old green dim
            "69, 133, 136"   # old blue dim
            "177, 98, 134"   # old purple dim
            "180, 164, 129"  # old sand dim
            "180, 128, 128"  # old rose dim
            "164, 135, 167"  # old lavender dim
            "137, 150, 70"   # old sage dim
        )
        # Get new accent RGB from hex (dim version for shadows)
        new_r=$((16#${accent_dim:1:2}))
        new_g=$((16#${accent_dim:3:2}))
        new_b=$((16#${accent_dim:5:2}))
        new_rgb="$new_r, $new_g, $new_b"

        for old_rgb in "${RGB_DIM[@]}"; do
            sed -i "s/$old_rgb/$new_rgb/g" "$GTK_CSS"
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
