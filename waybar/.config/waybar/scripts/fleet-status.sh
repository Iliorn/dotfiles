#!/bin/sh
# What hoth's fleet-push has waiting for this laptop: nothing (a green icon),
# a count of things that need a sudo run, or a failed last push.
# Asked over Tailscale SSH (fleet-status, from the ansible repo's
# roles/fleet_push), like hoth-status.sh.
#
#   fleet-status.sh        one JSON line for waybar (custom/fleet)
#   fleet-status.sh run    the module's click: list it and run it, asking for
#                          the sudo password, in a terminal
#
# The laptop's name is its tailnet name, which is what the ansible inventory
# and fleet-push go by; the hostname is only the fallback.
host=$(tailscale status --json 2>/dev/null |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].split(".")[0])' 2>/dev/null)
[ -n "$host" ] || host=$(uname -n)

if [ "${1:-}" = run ]; then
    ssh -t -o ConnectTimeout=5 hoth ".local/bin/fleet-status $host --run" || echo "hoth svarer ikke over SSH."
    printf '\nEnter lukker. '
    read -r _
    exit 0
fi

# Unreachable hoth is hoth-status.sh's to show; this one just stays hidden.
out=$(timeout 8 ssh -o BatchMode=yes -o ConnectTimeout=5 hoth ".local/bin/fleet-status $host --waybar" 2>/dev/null)
printf '%s\n' "${out:-{\"text\": \"\"\}}"
