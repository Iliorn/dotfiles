#!/bin/sh
# Restart a running swayosd-server inside the Hyprland session, so it reads
# its style.css and theme.css again (it only reads them when it starts).
# Used by theme.sh after a theme change and by the ansible repo's dotfiles
# reload hook after an update. Nothing to do when it is not running.
pkill -x swayosd-server >/dev/null 2>&1 || exit 0
sleep 0.3
exec "$(dirname "$0")/dispatch.sh" 'hl.dsp.exec_cmd("swayosd-server")' exec swayosd-server
