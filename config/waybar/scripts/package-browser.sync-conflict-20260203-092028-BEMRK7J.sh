#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────
#  Package Browser - Rofi menu for all installed packages
#  Shows package name and description
# ──────────────────────────────────────────────────────────────────────────

# Get all installed packages with descriptions
# Format: "package-name - description"
get_packages() {
    pacman -Qi | awk '
        /^Name/ { name = $3 }
        /^Description/ {
            desc = substr($0, index($0, ":") + 2)
            print name " - " desc
        }
    '
}

# Show rofi menu
selected=$(get_packages | rofi -dmenu -i \
    -theme ~/.config/rofi/package-browser.rasi \
    -p "Packages" \
    -mesg "All installed packages ($(pacman -Q | wc -l) total)")

# If something was selected, show package info
if [[ -n "$selected" ]]; then
    # Extract package name (everything before " - ")
    pkg_name=$(echo "$selected" | cut -d' ' -f1)

    # Show detailed package info in a new rofi window
    pacman -Qi "$pkg_name" | rofi -dmenu -i \
        -theme ~/.config/rofi/package-browser.rasi \
        -p "$pkg_name" \
        -mesg "Press Enter to close"
fi
