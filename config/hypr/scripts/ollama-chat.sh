#!/bin/bash
# Toggle Ollama chat - show/hide floating popup with gemma3:4b

# Check if ollama-chat window exists
window_addr=$(hyprctl clients -j | jq -r '.[] | select(.class == "ollama-chat") | .address' | head -1)

if [ -n "$window_addr" ]; then
    # Window exists - check if it's on special workspace (hidden)
    is_special=$(hyprctl clients -j | jq -r --arg addr "$window_addr" '.[] | select(.address == $addr) | .workspace.name' | grep -c "special")

    if [ "$is_special" -gt 0 ]; then
        # Hidden - bring to current workspace and focus
        hyprctl dispatch movetoworkspace "$(hyprctl activeworkspace -j | jq -r '.id'),address:$window_addr"
        hyprctl dispatch focuswindow address:$window_addr
    else
        # Visible - hide to special workspace
        hyprctl dispatch movetoworkspacesilent special:ollama,address:$window_addr
    fi
else
    # Not running - start ollama serve if needed, then launch
    if ! pgrep -x "ollama" > /dev/null; then
        ollama serve &>/dev/null &
        sleep 2
    fi

    # Launch with inline window rules for floating popup with glass effect
    hyprctl dispatch exec "[float;size 500 400;move 100%-520 50;pin] alacritty -o window.opacity=0.75 --class ollama-chat -e ollama run gemma3:4b"
fi
