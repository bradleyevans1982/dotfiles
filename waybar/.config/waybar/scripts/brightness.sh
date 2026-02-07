#!/bin/bash
# ── brightness.sh ─────────────────────────────────────────
# Description: Shows current brightness with ASCII bar + tooltip
# Usage: Waybar `custom/brightness` every 2s
# Dependencies: brightnessctl, seq, printf, awk
#  ─────────────────────────────────────────────────────────

# Get theme from color file
COLOR_FILE="/tmp/gruvbox-current-accent"
theme=""
if [[ -f "$COLOR_FILE" ]]; then
    theme=$(cat "$COLOR_FILE")
fi

# Get brightness percentage
brightness=$(brightnessctl get)
max_brightness=$(brightnessctl max)
percent=$((brightness * 100 / max_brightness))

# Build ASCII bar
filled=$((percent / 10))
empty=$((10 - filled))
bar=$(printf '█%.0s' $(seq 1 $filled))
pad=$(printf '░%.0s' $(seq 1 $empty))
ascii_bar="[$bar$pad]"

# Icon
icon="󰛨"

# Color logic
if [[ "$theme" == "original" ]]; then
    # Original multi-color logic
    if [ "$percent" -lt 20 ]; then
        fg="#fb4934"  # red
    elif [ "$percent" -lt 55 ]; then
        fg="#fe8019"  # orange
    else
        fg="#8ec07c"  # aqua/cyan
    fi
elif [[ "$theme" =~ ^# ]]; then
    fg="$theme"
else
    fg="#b8bb26"  # fallback green
fi

# Device name (first column from brightnessctl --machine-readable)
device=$(brightnessctl --machine-readable | awk -F, 'NR==1 {print $1}')

# Tooltip text
tooltip="Brightness: $percent%\nDevice: $device"

# JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $percent%</span>\",\"tooltip\":\"$tooltip\"}"
