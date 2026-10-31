#!/bin/sh
# hoth's health as a dot in the bar: green when everything answers, red with
# a count when something does not, grey when hoth cannot be asked.
#
# The answer comes from hoth itself (~/.local/bin/hoth-status, installed by
# the ansible repo's roles/health_alarm), which only reads what the alarm's
# own sweep last found. Asking over Tailscale SSH needs no service, port or
# token on hoth, and costs about 0.4 s once a minute.
#
#   hoth-status.sh         one JSON line for waybar (custom/hoth)
#   hoth-status.sh view    the full list in a terminal (the module's click)
remote() {
    timeout 8 ssh -o BatchMode=yes -o ConnectTimeout=5 hoth ".local/bin/hoth-status $*"
}

if [ "${1:-}" = view ]; then
    remote || echo "hoth svarer ikke over SSH."
    printf '\nEnter lukker. '
    read -r _
    exit 0
fi

# Unreachable is its own state, not "everything is fine": the dot goes grey.
out=$(remote --waybar 2>/dev/null)
if [ -n "$out" ]; then
    printf '%s\n' "$out"
else
    printf '%s\n' '{"text": "○", "tooltip": "hoth svarer ikke", "class": "offline"}'
fi
