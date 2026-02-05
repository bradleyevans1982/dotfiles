#!/bin/bash
# Randomly select a wallpaper from the wallpapers directory

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Ensure swww daemon is running
if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon &
    sleep 1
fi

# Dynamically find all wallpapers (jpg, jpeg, png), excluding black.png and bg_wallpaper.png
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) ! -name "black.png" ! -name "bg_wallpaper.png" 2>/dev/null)

# Exit if no wallpapers found
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Pick a random wallpaper
RANDOM_WALLPAPER="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

# Set wallpaper with swww (with fade transition)
swww img "$RANDOM_WALLPAPER" --transition-type fade --transition-duration 1
