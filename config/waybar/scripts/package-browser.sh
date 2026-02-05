#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────
#  Package Browser - Rofi menu for explicitly installed packages
#  Shows package name (bold) and description
# ──────────────────────────────────────────────────────────────────────────

# Get explicitly installed packages with descriptions
# Format: "<b>package-name</b>  description" (Pango markup)
get_packages() {
    # Get list of explicitly installed packages
    for pkg in $(pacman -Qeq); do
        desc=$(pacman -Qi "$pkg" 2>/dev/null | awk -F': ' '/^Description/ {print $2}')
        echo "<b><span foreground='#fabd2f'>$pkg</span></b>  $desc"
    done
}

# Count explicitly installed packages
pkg_count=$(pacman -Qe | wc -l)

# Show rofi menu
selected=$(get_packages | rofi -dmenu -i \
    -markup-rows \
    -theme ~/.config/rofi/package-browser.rasi \
    -p "Packages" \
    -mesg "Explicitly installed packages ($pkg_count total)")

# If something was selected, show package info
if [[ -n "$selected" ]]; then
    # Extract package name (strip pango markup)
    pkg_name=$(echo "$selected" | sed 's/<[^>]*>//g' | awk '{print $1}')

    # Show detailed package info in a new rofi window
    pacman -Qi "$pkg_name" | rofi -dmenu -i \
        -theme ~/.config/rofi/package-browser.rasi \
        -p "$pkg_name" \
        -mesg "Press Enter to close"
fi
