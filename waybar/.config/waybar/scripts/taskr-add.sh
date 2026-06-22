#!/bin/bash
# Quick-add a task via taskr. Bound to right-click on the waybar
# taskr-status module; the full TUI is on left-click.

set -eo pipefail

echo "Title:"
read -r title
[ -z "$title" ] && { echo "(empty, aborting)"; sleep 1; exit 0; }

echo "Due (blank | today | tomorrow | +3d | dd-mm-yy):"
read -r due

if [ -n "$due" ]; then
    taskr add "$title" -due "$due"
else
    taskr add "$title"
fi

notify-send "✓ Task added" "$title" -i emblem-default
sleep 0.5
