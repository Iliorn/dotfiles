#!/bin/sh
# The dropdown terminal (super+D): one floating alacritty that lives on the
# special workspace "dropterm" and slides over whatever is open when called.
#
# Started on demand, not at login, so it costs nothing until it is used. The
# window rule in hyprland.{lua,conf} matches the class below and sends the
# window to special:dropterm SILENT, so a freshly started terminal opens hidden
# and this script is the only thing that ever shows it. That is what keeps
# "start it" and "toggle it" from fighting: a rule that showed the workspace
# itself would be toggled straight back off by the toggle below.
#
# Plain `hyprctl clients` and grep, not -j: no jq needed. The class line is
# "\tclass: dropterm" in that output.
class=dropterm

if ! hyprctl clients | grep -q "^[[:space:]]*class: $class\$"; then
    setsid -f alacritty --class "$class" >/dev/null 2>&1
    # The window has to exist before the workspace has anything to show.
    # Two seconds is far more than alacritty needs; if it never turns up the
    # toggle below is a harmless empty special workspace.
    i=0
    while [ "$i" -lt 20 ]; do
        hyprctl clients | grep -q "^[[:space:]]*class: $class\$" && break
        sleep 0.1
        i=$((i + 1))
    done
fi

exec "$(dirname "$0")/dispatch.sh" 'hl.dsp.workspace.toggle_special("dropterm")' \
    togglespecialworkspace dropterm
