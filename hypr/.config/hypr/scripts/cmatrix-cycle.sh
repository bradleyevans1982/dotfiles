#!/bin/bash
# Color-cycling cmatrix for Gruvbox theme

COLORS=(green yellow red blue cyan magenta)

while true; do
    for color in "${COLORS[@]}"; do
        timeout 10 cmatrix -B -u 2 -C "$color" || true
    done
done
