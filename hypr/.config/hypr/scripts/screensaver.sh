#!/bin/bash
# Screensaver launcher - switch between different screensavers
# Usage: screensaver.sh [cmatrix|arch|random]
# Default: random

SCRIPT_DIR="$HOME/.config/hypr/scripts"
SCREENSAVER="${1:-random}"

# Kill any running screensaver first
pkill -f "alacritty.*screensaver"

# Available screensavers
SCREENSAVERS=(cmatrix arch)

# Pick random if requested
if [[ "$SCREENSAVER" == "random" ]]; then
    SCREENSAVER="${SCREENSAVERS[$((RANDOM % ${#SCREENSAVERS[@]}))]}"
fi

case "$SCREENSAVER" in
    cmatrix)
        exec "$SCRIPT_DIR/screensaver-cmatrix.sh"
        ;;
    arch)
        exec "$SCRIPT_DIR/screensaver-arch.sh"
        ;;
    *)
        echo "Unknown screensaver: $SCREENSAVER"
        echo "Available: cmatrix, arch, random"
        exit 1
        ;;
esac
