#!/bin/sh
# hoth's health as the colour of the server icon: green when everything
# answers, red with a count when something does not, yellow when hoth cannot
# be asked, grey when its own check has stalled.
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

# hoth still answers with a dot (● / ● 3 / ○); the icon carries the colour
# now, so only the count is kept, with the space before it. config.jsonc's
# format has no space of its own, so a healthy hoth is the bare icon.
# Unreachable is its own state, not "everything is fine": class offline.
out=$(remote --waybar 2>/dev/null)
if [ -n "$out" ]; then
    # Two literal patterns, not [●○]: in the C locale waybar may start us in,
    # a bracket matches single bytes and would cut the dot in half.
    printf '%s\n' "$out" | sed -e 's/"text": "●/"text": "/' -e 's/"text": "○/"text": "/'
else
    printf '%s\n' '{"text": "", "tooltip": "hoth svarer ikke", "class": "offline"}'
fi
