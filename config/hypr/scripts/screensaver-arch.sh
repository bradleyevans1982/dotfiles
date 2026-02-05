#!/bin/bash
# Arch Logo Screensaver for Hyprland

pkill -f "alacritty.*screensaver" 2>/dev/null
sleep 0.1

# Launch alacritty
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
alacritty --class screensaver -o 'window.decorations="None"' -o 'colors.primary.background="#000000"' \
    -e bash -c '
        sleep 0.5
        /home/bradv/.config/hypr/scripts/arch-logo-anim.sh
    ' &

# Wait for window to appear then fullscreen it
for i in {1..20}; do
    sleep 0.1
    ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class=="screensaver") | .address' | head -1)
    if [[ -n "$ADDR" ]]; then
        hyprctl dispatch focuswindow address:$ADDR
        hyprctl dispatch fullscreen 0 set

        # Start mouse movement monitor in background
        (
            INITIAL_POS=$(hyprctl cursorpos)
            while true; do
                sleep 0.2
                pgrep -f "alacritty.*screensaver" > /dev/null || exit 0
                CURRENT_POS=$(hyprctl cursorpos)
                if [[ "$CURRENT_POS" != "$INITIAL_POS" ]]; then
                    pkill -f "alacritty.*screensaver"
                    exit 0
                fi
            done
        ) &
        disown
        exit 0
    fi
done
