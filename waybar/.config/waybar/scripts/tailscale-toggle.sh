#!/bin/bash
# Toggle Tailscale on/off (requires passwordless sudo for tailscale)

# Check if tailscale is running (status command returns 0 when running)
if tailscale status &>/dev/null; then
    sudo -n tailscale down
    notify-send "Tailscale" "Disconnected" 2>/dev/null
else
    sudo -n tailscale up --reset
    notify-send "Tailscale" "Connected" 2>/dev/null
fi
