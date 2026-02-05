#!/bin/bash
# Power status for waybar - shows power profile state

profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)

case "$profile" in
    "low-power")
        echo '{"text": "[󰤆]", "class": "powersaver", "tooltip": "Power Menu (Power Saver)"}'
        ;;
    "performance")
        echo '{"text": "[󰤆]", "class": "performance", "tooltip": "Power Menu (Performance)"}'
        ;;
    *)
        echo '{"text": "[󰤆]", "class": "", "tooltip": "Power Menu"}'
        ;;
esac
