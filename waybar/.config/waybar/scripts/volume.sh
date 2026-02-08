#!/bin/bash
# ── volume.sh ─────────────────────────────────────────────
# Description: Shows current audio volume with ASCII bar + tooltip
# Usage: Waybar `custom/volume` every 1s
# Dependencies: wpctl, awk, bc, seq, printf
# ───────────────────────────────────────────────────────────

# Get theme from color file
COLOR_FILE="/tmp/gruvbox-current-accent"
theme=""
if [[ -f "$COLOR_FILE" ]]; then
    theme=$(cat "$COLOR_FILE")
fi

# Get raw volume and convert to int
vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{ print $2 }')
vol_int=$(echo "$vol_raw * 100" | bc | awk '{ print int($1) }')

# Check mute status
is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo true || echo false)

# Get default sink description (human-readable)
sink=$(wpctl status | awk '/Sinks:/,/Sources:/' | grep '\*' | cut -d'.' -f2- | sed 's/^\s*//; s/\[.*//')

# Icon logic (using Material Design icons that render in JetBrainsMono NFM)
if [ "$is_muted" = true ]; then
  icon="󰖁"
  vol_int=0
elif [ "$vol_int" -lt 50 ]; then
  icon="󰕿"
else
  icon="󰕾"
fi

# ASCII bar
filled=$((vol_int / 10))
empty=$((10 - filled))
bar=$(printf '█%.0s' $(seq 1 $filled))
pad=$(printf '░%.0s' $(seq 1 $empty))
ascii_bar="[$bar$pad]"

# Color logic
if [ "$is_muted" = true ]; then
    fg="#fb4934"  # always red when muted
elif [[ "$theme" == "original" ]]; then
    # Original multi-color logic
    if [ "$vol_int" -lt 10 ]; then
        fg="#fb4934"  # red
    elif [ "$vol_int" -lt 50 ]; then
        fg="#fe8019"  # orange
    else
        fg="#b8bb26"  # green
    fi
elif [[ "$theme" =~ ^# ]]; then
    fg="$theme"
else
    fg="#b8bb26"  # fallback green
fi

# Tooltip text
if [ "$is_muted" = true ]; then
  tooltip="Audio: Muted\nOutput: $sink"
else
  tooltip="Audio: $vol_int%\nOutput: $sink"
fi

# Final JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $vol_int%</span>\",\"tooltip\":\"$tooltip\"}"
