#!/bin/bash
# Auto-notify on track change
# Polls playerctl and sends a brief notification when track changes

LAST_TRACK=""

# Check if browser window is focused
is_browser_focused() {
    local active_class
    active_class=$(hyprctl activewindow -j 2>/dev/null | grep -o '"class": "[^"]*"' | cut -d'"' -f4)
    [[ "$active_class" == "firefox" || "$active_class" == "chromium" || "$active_class" == "google-chrome" || "$active_class" == "brave-browser" ]]
}

# Function to send notification
send_notification() {
    local title="$1"
    local artist="$2"
    local art_url="$3"
    local url="$4"

    # Skip if no title
    [[ -z "$title" ]] && return

    # Check if this is YouTube - only notify if browser is NOT focused
    if [[ "$url" == *"youtube.com"* ]] || [[ "$url" == *"youtu.be"* ]]; then
        if is_browser_focused; then
            return
        fi
    fi

    # Get album art path
    local art_path=""
    if [[ -n "$art_url" ]]; then
        if [[ "$art_url" == http* ]]; then
            local tmp_art="/tmp/album-art-$(echo "$art_url" | md5sum | cut -d' ' -f1).jpg"
            if [[ ! -f "$tmp_art" ]]; then
                curl -s "$art_url" -o "$tmp_art" 2>/dev/null
            fi
            [[ -f "$tmp_art" && -s "$tmp_art" ]] && art_path="$tmp_art"
        elif [[ "$art_url" == file://* ]]; then
            local file_path="${art_url#file://}"
            [[ -f "$file_path" ]] && art_path="$file_path"
        fi
    fi

    # Build notification body
    local body=""
    [[ -n "$artist" ]] && body="$artist"

    # Send notification with short timeout (2000ms = 2 seconds)
    if [[ -n "$art_path" ]]; then
        notify-send -t 2000 -i "$art_path" "$title" "$body" 2>/dev/null
    else
        notify-send -t 2000 "Now Playing" "$title${body:+ - $body}" 2>/dev/null
    fi
}

# Poll for changes every 2 seconds
while true; do
    # Get current track info
    title=$(playerctl metadata title 2>/dev/null)
    artist=$(playerctl metadata artist 2>/dev/null)
    art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)
    url=$(playerctl metadata xesam:url 2>/dev/null)
    status=$(playerctl status 2>/dev/null)

    # Create track identifier
    current_track="$title|$artist"

    # Only notify if track changed, has a title, and is playing
    if [[ "$current_track" != "$LAST_TRACK" && -n "$title" && "$status" == "Playing" ]]; then
        LAST_TRACK="$current_track"
        send_notification "$title" "$artist" "$art_url" "$url"
    fi

    sleep 2
done
