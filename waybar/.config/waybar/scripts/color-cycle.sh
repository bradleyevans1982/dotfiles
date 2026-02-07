#!/bin/bash
# Cycles through Gruvbox colors, outputting a class name for CSS styling

colors=("red" "orange" "yellow" "green" "aqua" "blue" "purple")

# Get current second and use modulo to pick a color
index=$(( $(date +%s) % ${#colors[@]} ))

echo "{\"text\": \"●\", \"class\": \"${colors[$index]}\"}"
