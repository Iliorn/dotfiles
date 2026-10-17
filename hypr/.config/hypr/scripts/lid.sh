#!/bin/sh
# Remember whether the lid is shut, then let screens.sh act on it.
#
# This script used to do the work itself with `hyprctl keyword monitor
# <panel>, disable`, which lived only in the running config: the next
# `hyprctl reload` re-enabled the panel and pulled the pinned workspaces back
# onto a closed lid. The lid state is now a file, and screens.sh writes a
# config file from it, so a reload keeps the truth.
#
# With no second screen this still does nothing visible: screens.sh refuses to
# disable the only output, and logind handles the lid as it always has
# (HandleLidSwitch=suspend). Docked, logind does not suspend, which is the
# whole reason this exists.
set -eu

state_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/state"
lid_flag="$state_dir/lid-closed"
mkdir -p "$state_dir"

case "${1:-}" in
close) : > "$lid_flag" ;;
open)  rm -f "$lid_flag" ;;
*)     echo "usage: lid.sh close|open" >&2; exit 2 ;;
esac

exec "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/screens.sh"
