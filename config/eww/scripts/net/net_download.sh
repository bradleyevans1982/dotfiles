#!/usr/bin/env bash
# Network download speed in KB/s or MB/s

iface="wlan0"

rx1=$(awk -v iface="$iface" '$1 ~ iface {gsub(":", "", $1); print $2}' /proc/net/dev)
sleep 1
rx2=$(awk -v iface="$iface" '$1 ~ iface {gsub(":", "", $1); print $2}' /proc/net/dev)

bps=$((rx2 - rx1))
kbps=$((bps / 1024))

if [ "$kbps" -ge 1024 ]; then
  mbps=$(echo "scale=1; $kbps / 1024" | bc)
  echo "${mbps} MB/s"
else
  echo "${kbps} KB/s"
fi
