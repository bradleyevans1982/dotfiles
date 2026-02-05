#!/usr/bin/env bash
# Network upload speed in KB/s or MB/s

iface="wlan0"

tx1=$(awk -v iface="$iface" '$1 ~ iface {gsub(":", "", $1); print $10}' /proc/net/dev)
sleep 1
tx2=$(awk -v iface="$iface" '$1 ~ iface {gsub(":", "", $1); print $10}' /proc/net/dev)

bps=$((tx2 - tx1))
kbps=$((bps / 1024))

if [ "$kbps" -ge 1024 ]; then
  mbps=$(echo "scale=1; $kbps / 1024" | bc)
  echo "${mbps} MB/s"
else
  echo "${kbps} KB/s"
fi
