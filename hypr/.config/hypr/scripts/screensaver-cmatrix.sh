#!/bin/bash
# Cmatrix Screensaver for Hyprland

pkill -f "alacritty.*screensaver" 2>/dev/null
sleep 0.1

# Create a temp script that waits then runs cmatrix
TMPSCRIPT=$(mktemp)
cat > "$TMPSCRIPT" << 'INNEREOF'
#!/bin/bash
# Wait for fullscreen signal
while [[ ! -f /tmp/screensaver-ready ]]; do sleep 0.1; done
rm -f /tmp/screensaver-ready
exec cmatrix -B -u 2 -C green
INNEREOF
chmod +x "$TMPSCRIPT"

# Clean up signal file
rm -f /tmp/screensaver-ready

# Launch alacritty with waiting script
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
alacritty --class screensaver -o 'window.decorations="None"' -o 'colors.primary.background="#000000"' \
    -e "$TMPSCRIPT" &

# Wait for window to appear then fullscreen it
for i in {1..20}; do
    sleep 0.1
    ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class=="screensaver") | .address' | head -1)
    if [[ -n "$ADDR" ]]; then
        hyprctl dispatch focuswindow address:$ADDR
        hyprctl dispatch fullscreen 0 set
        sleep 0.1
        # Signal cmatrix to start now that we're fullscreen
        touch /tmp/screensaver-ready

        # Start mouse movement monitor
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
