#!/usr/bin/env bash
# Toggle Open WebUI - focus if running, launch if not, minimize if focused

WINDOW_CLASS="brave-browser"
APP_URL="http://100.121.37.7:3000/"

# Check if Open WebUI window exists
window_id=$(hyprctl clients -j | jq -r '.[] | select(.initialTitle | test("Open WebUI|100.121.37.7")) | .address' | head -1)

if [ -n "$window_id" ]; then
    # Window exists - check if it's focused
    active_window=$(hyprctl activewindow -j | jq -r '.address')

    if [ "$window_id" = "$active_window" ]; then
        # Already focused - minimize/move to special workspace
        hyprctl dispatch movetoworkspacesilent special:openwebui,address:$window_id
    else
        # Not focused - bring to current workspace and focus
        hyprctl dispatch movetoworkspace "$(hyprctl activeworkspace -j | jq -r '.id'),address:$window_id"
        hyprctl dispatch focuswindow address:$window_id
    fi
else
    # Not running - launch it
    brave --app="$APP_URL" &
fi
