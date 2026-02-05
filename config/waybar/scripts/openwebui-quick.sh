#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Open WebUI Quick Launcher
# Shows a small rofi prompt, then opens the full UI with your message
# ──────────────────────────────────────────────────────────────────────────

APP_URL="http://100.121.37.7:3000/"

# Model list - customize these based on your Ollama setup
MODELS=(
    "llama3.2:latest"
    "codellama:latest"
    "mistral:latest"
    "deepseek-coder:latest"
    "qwen2.5:latest"
)

# Step 1: Select model
model=$(printf '%s\n' "${MODELS[@]}" | rofi -dmenu \
    -i \
    -p "Model" \
    -theme-str 'window {width: 300px; height: 200px; location: center;}' \
    -theme-str 'listview {lines: 6;}' \
    -theme-str 'inputbar {enabled: true;}' \
    -theme-str 'element {padding: 8px;}')

# Exit if no model selected
[ -z "$model" ] && exit 0

# Step 2: Get prompt
prompt=$(rofi -dmenu \
    -p "Ask $model" \
    -theme-str 'window {width: 500px; height: 80px; location: center;}' \
    -theme-str 'listview {enabled: false;}' \
    -theme-str 'inputbar {enabled: true;}' \
    -theme-str 'entry {placeholder: "Type your message...";}' \
    -lines 0)

# Exit if no prompt entered
[ -z "$prompt" ] && exit 0

# Step 3: Check if Open WebUI is already running
window_id=$(hyprctl clients -j | jq -r '.[] | select(.initialTitle | test("Open WebUI|100.121.37.7")) | .address' | head -1)

if [ -z "$window_id" ]; then
    # Launch Open WebUI
    brave --app="$APP_URL" &
    # Wait for window to appear
    for i in {1..30}; do
        sleep 0.2
        window_id=$(hyprctl clients -j | jq -r '.[] | select(.initialTitle | test("Open WebUI|100.121.37.7")) | .address' | head -1)
        [ -n "$window_id" ] && break
    done
    # Extra wait for page to load
    sleep 1.5
else
    # Bring existing window to focus
    hyprctl dispatch focuswindow address:$window_id
    sleep 0.3
fi

# Step 4: Type the prompt using wtype
# First, we need to make sure the input field is focused
# Open WebUI usually has the input focused by default

# Type the prompt (wtype handles special characters)
wtype -d 50 "$prompt"

# Optional: Press Enter to submit (uncomment if you want auto-submit)
# sleep 0.2
# wtype -k Return
