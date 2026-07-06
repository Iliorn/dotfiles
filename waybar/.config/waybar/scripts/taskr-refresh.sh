#!/usr/bin/env bash
# Debounce SQLite writes, then ask Waybar to refresh only the taskr module.
sleep 0.15
pkill -RTMIN+8 waybar 2>/dev/null || true
