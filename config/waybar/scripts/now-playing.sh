#!/bin/bash
# Now Playing widget for Waybar
# Displays current media with animated equalizer

# Equalizer animation - randomized bars for dynamic effect
get_eq_frame() {
    bars=("▂" "▃" "▄" "▅" "▆" "▇" "█")
    eq=""
    for i in {1..6}; do
        eq+="${bars[RANDOM % 7]}"
    done
    echo "$eq"
}

get_info() {
    player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)
    status=$(playerctl status 2>/dev/null)
    title=$(playerctl metadata --format '{{title}}' 2>/dev/null)
    artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
    album=$(playerctl metadata --format '{{album}}' 2>/dev/null)

    # If no player or no title, return empty
    if [[ -z "$player" ]] || [[ -z "$title" ]]; then
        echo '{"text": "", "tooltip": "No media playing", "class": "stopped"}'
        return
    fi

    # Truncate title if too long
    if [[ ${#title} -gt 20 ]]; then
        title="${title:0:17}..."
    fi

    # Truncate artist if too long
    if [[ ${#artist} -gt 15 ]]; then
        artist="${artist:0:12}..."
    fi

    # Build display text based on status
    if [[ "$status" == "Playing" ]]; then
        eq=$(get_eq_frame)
        if [[ -n "$artist" ]]; then
            text="$eq  $artist - $title"
        else
            text="$eq  $title"
        fi
    else
        # Paused - show pause icon
        if [[ -n "$artist" ]]; then
            text="󰏤  $artist - $title"
        else
            text="󰏤  $title"
        fi
    fi

    # Build tooltip with more details
    tooltip="$title"
    [[ -n "$artist" ]] && tooltip="$tooltip\nby $artist"
    [[ -n "$album" ]] && tooltip="$tooltip\non $album"
    tooltip="$tooltip\n\nPlayer: $player"
    tooltip="$tooltip\n\nLeft-click: Play/Pause"
    tooltip="$tooltip\nRight-click: Show artwork"
    tooltip="$tooltip\nScroll: Next/Previous"

    # Escape for JSON
    text=$(echo "$text" | sed 's/"/\\"/g')
    tooltip=$(echo "$tooltip" | sed 's/"/\\"/g')

    class=$(echo "$status" | tr '[:upper:]' '[:lower:]')

    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
}

# Continuous output mode for waybar
while true; do
    get_info
    status=$(playerctl status 2>/dev/null)
    if [[ "$status" == "Playing" ]]; then
        sleep 0.3   # Fast updates for animation
    else
        sleep 2     # Slow updates when paused/stopped
    fi
done
