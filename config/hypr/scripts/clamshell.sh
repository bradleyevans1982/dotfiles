#!/bin/bash
# Clamshell mode handler for Hyprland
# Disables internal display when lid is closed AND external display is connected

INTERNAL_DISPLAY="eDP-1"
STATE_FILE="/tmp/clamshell_scale"
SUSPEND_LOCK="/tmp/clamshell_suspend_lock"

# Debounce: prevent suspend if we just woke up (within 3 seconds)
check_debounce() {
    if [[ -f "$SUSPEND_LOCK" ]]; then
        last_suspend=$(cat "$SUSPEND_LOCK")
        now=$(date +%s)
        if (( now - last_suspend < 3 )); then
            return 1  # Too soon, skip
        fi
    fi
    return 0
}

# Get list of active monitors (excluding the internal one)
get_external_monitors() {
    hyprctl monitors -j | jq -r ".[] | select(.name != \"$INTERNAL_DISPLAY\") | .name"
}

# Save internal display scale before disabling
save_internal_scale() {
    hyprctl monitors -j | jq -r ".[] | select(.name == \"$INTERNAL_DISPLAY\") | .scale" > "$STATE_FILE"
}

case "$1" in
    close)
        external=$(get_external_monitors)
        if [[ -n "$external" ]]; then
            # Save current scale before disabling
            save_internal_scale
            # External display connected - disable internal, stay awake
            hyprctl keyword monitor "$INTERNAL_DISPLAY, disable"
            notify-send -u low "Clamshell Mode" "Lid closed - using external display"
        else
            # No external display - lock and suspend (with debounce)
            if check_debounce; then
                pidof hyprlock || hyprlock &
                sleep 1
                date +%s > "$SUSPEND_LOCK"
                exec systemctl suspend
            fi
        fi
        ;;
    open)
        # Record wake time to prevent immediate re-suspend
        date +%s > "$SUSPEND_LOCK"
        # Get saved scale or use default
        if [[ -f "$STATE_FILE" ]]; then
            scale=$(cat "$STATE_FILE")
        else
            scale="1.57"
        fi
        # Re-enable internal display with saved scale
        hyprctl keyword monitor "$INTERNAL_DISPLAY, preferred, auto, $scale"
        # Turn on DPMS in case display was off
        hyprctl dispatch dpms on
        # Only notify if external display is connected (actual clamshell mode)
        external=$(get_external_monitors)
        if [[ -n "$external" ]]; then
            notify-send -u low "Clamshell Mode" "Lid opened - internal display enabled"
        fi
        ;;
    *)
        echo "Usage: $0 {close|open}"
        exit 1
        ;;
esac
