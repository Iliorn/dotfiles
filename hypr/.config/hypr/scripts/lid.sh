#!/bin/sh
# Closing the lid hands the session to the external screen instead of
# stranding half the workspaces on a panel nobody can see.
#
# Hyprland leaves the internal panel ENABLED when the lid shuts, so every
# workspace living there just goes dark and stays put — the workspaces
# look "missing". Disabling the panel makes Hyprland migrate them to the
# remaining monitor; re-enabling it brings back the ones host.conf pins to
# it.
#
# The panel's name differs per machine (eDP-1 on the T480, LVDS-1 on the
# Sandy Bridge X220s), so it is DETECTED, not configured. That keeps this
# script identical on every laptop.
#
# With no second monitor this does nothing: disabling the only output
# would leave the session nowhere to draw. logind then handles the lid as
# it always has (HandleLidSwitch=suspend). With an external screen
# attached logind already treats the machine as docked and does not
# suspend, which is why this script is needed at all.

internal=$(hyprctl monitors all | awk '/^Monitor (eDP|LVDS|DSI)/ { print $2; exit }')
[ -n "$internal" ] || exit 0

case "${1:-}" in
close)
    # Hand over only if something else is actually lit.
    enabled=$(hyprctl monitors | grep -c '^Monitor ')
    [ "${enabled:-0}" -gt 1 ] || exit 0
    hyprctl keyword monitor "$internal, disable"
    ;;
open)
    hyprctl keyword monitor "$internal, preferred, auto, 1"
    ;;
esac
