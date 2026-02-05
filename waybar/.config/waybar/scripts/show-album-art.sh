#!/bin/bash
# Show album art for current media

art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

if [[ -z "$art_url" ]]; then
    notify-send "Now Playing" "No album art available" 2>/dev/null
    exit 0
fi

# Download art to temp file if it's a URL
if [[ "$art_url" == http* ]]; then
    tmp_art="/tmp/album-art-$(echo "$art_url" | md5sum | cut -d' ' -f1).jpg"
    if [[ ! -f "$tmp_art" ]]; then
        curl -s "$art_url" -o "$tmp_art" 2>/dev/null
    fi
    art_path="$tmp_art"
elif [[ "$art_url" == file://* ]]; then
    art_path="${art_url#file://}"
else
    art_path="$art_url"
fi

# Show notification with album art
if [[ -f "$art_path" ]]; then
    notify-send -i "$art_path" "$title" "$artist" 2>/dev/null
else
    notify-send "Now Playing" "$title\n$artist" 2>/dev/null
fi
