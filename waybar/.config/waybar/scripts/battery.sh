#!/bin/bash
# ── battery.sh ─────────────────────────────────────────
# Description: Shows battery % with ASCII bar + dynamic tooltip
# Usage: Waybar `custom/battery` every 10s
# Dependencies: upower, awk, seq, printf
#  ──────────────────────────────────────────────────────

# Get theme from color file
COLOR_FILE="/tmp/gruvbox-current-accent"
theme=""
if [[ -f "$COLOR_FILE" ]]; then
    theme=$(cat "$COLOR_FILE")
fi

capacity=$(cat /sys/class/power_supply/BAT1/capacity)
status=$(cat /sys/class/power_supply/BAT1/status)

# Get detailed info from upower
time_to_empty=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | awk -F: '/time to empty/ {print $2}' | xargs)
time_to_full=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | awk -F: '/time to full/ {print $2}' | xargs)

# Icons
charging_icons=(󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)
default_icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)

index=$((capacity / 10))
[ $index -ge 10 ] && index=9

if [[ "$status" == "Charging" ]]; then
    icon=${charging_icons[$index]}
elif [[ "$status" == "Full" ]]; then
    icon="󰂅"
else
    icon=${default_icons[$index]}
fi

# ASCII bar
filled=$((capacity / 10))
empty=$((10 - filled))
bar=$(printf '█%.0s' $(seq 1 $filled))
pad=$(printf '░%.0s' $(seq 1 $empty))
ascii_bar="[$bar$pad]"

# Color logic
if [[ "$theme" == "original" ]]; then
    # Original multi-color logic
    if [ "$capacity" -lt 20 ]; then
        fg="#fb4934"  # red
    elif [ "$capacity" -lt 55 ]; then
        fg="#fe8019"  # orange
    else
        fg="#8ec07c"  # aqua/cyan
    fi
else
    # Use accent color (theme is the hex color)
    if [ "$capacity" -lt 15 ]; then
        fg="#fb4934"  # always red for critical
    elif [[ "$theme" =~ ^# ]]; then
        fg="$theme"
    else
        fg="#b8bb26"  # fallback green
    fi
fi

# Tooltip
if [[ "$status" == "Charging" && -n "$time_to_full" ]]; then
    tooltip="Charging: $capacity%\nTime to full: $time_to_full"
elif [[ "$status" == "Discharging" && -n "$time_to_empty" ]]; then
    tooltip="Battery: $capacity%\nTime remaining: $time_to_empty"
else
    tooltip="Battery: $capacity%\nStatus: $status"
fi

# JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $capacity%</span>\",\"tooltip\":\"$tooltip\"}"
