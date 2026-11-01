#!/bin/sh
# Where the laptop's internet goes, as the colour of a VPN icon:
#   green  out through hoth (Tailscale exit node)
#   grey   straight out, at home (where hoth is behind the same router)
#   red    straight out on someone else's network, or Tailscale stopped
# The click opens tsui (Tailscale's TUI) as a dropdown, to change it by hand.
#
# Home or away comes from the ansible repo's roles/exit_node, whose timer
# writes it to /run/exit-node-auto/location; that same timer is what picks
# the exit node. Without the file (role not run yet) away is assumed, which
# shows red rather than a reassuring grey.
status=$(tailscale status --json 2>/dev/null) || status=""
backend=$(printf '%s' "$status" | jq -r '.BackendState // empty' 2>/dev/null)
exit_online=$(printf '%s' "$status" | jq -r '.ExitNodeStatus.Online // empty' 2>/dev/null)
location=$(cat /run/exit-node-auto/location 2>/dev/null || echo away)

if [ "$backend" != Running ]; then
    class=down tooltip="Tailscale er slukket"
elif [ "$exit_online" = true ]; then
    class=exit tooltip="Internet via hoth"
elif [ -n "$exit_online" ]; then
    class=down tooltip="Exit node valgt, men hoth svarer ikke"
elif [ "$location" = home ]; then
    class=home tooltip="Hjemme: internet direkte"
else
    class=direct tooltip="Fremmed netværk: internet direkte, ikke via hoth"
fi
printf '{"text": "", "tooltip": "%s", "class": "%s"}\n' "$tooltip" "$class"
