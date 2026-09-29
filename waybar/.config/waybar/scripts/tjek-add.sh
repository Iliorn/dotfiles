#!/bin/bash
# Quick-add a task via tjek. Bound to right-click on the waybar
# tjek-status module; the full TUI is on left-click.

set -eo pipefail

echo "Title:"
read -r title
[ -z "$title" ] && { echo "(empty, aborting)"; sleep 1; exit 0; }

echo "Due (blank | today | tomorrow | +3d | dd-mm-yy):"
read -r due

if [ -n "$due" ]; then
    tjek add "$title" -due "$due"
else
    tjek add "$title"
fi

notify-send "✓ Task added" "$title" -i emblem-default
sleep 0.5
