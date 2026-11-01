#!/bin/sh
# A TUI as a dropdown, the same way as the terminal on super+D:
#
#   dropdown.sh <name> <command> [args...]
#
# e.g. dropdown.sh tsui tsui. Starts `alacritty --class drop-<name> -e
# <command>` once, on its own special workspace drop-<name>, and from then on
# only shows or hides it. Waybar's icons and the system menu open their TUIs
# through this.
#
# <name> must be in the `dropdowns` list in hyprland.lua: that is where the
# window rule comes from that floats the window, gives it the dropdown's
# size and place, and sends it SILENT to its special workspace (see
# dropterm.sh for why silent). A name that is not there opens as an ordinary
# window instead, which is a visible mistake rather than a broken one.
#
# Quitting the TUI (q) closes the window, and an empty special workspace
# hides itself, so the next click starts it fresh.
[ $# -ge 2 ] || { echo "usage: dropdown.sh <name> <command> [args...]" >&2; exit 2; }
name=$1
shift
class="drop-$name"

if ! hyprctl clients | grep -q "^[[:space:]]*class: $class\$"; then
    setsid -f alacritty --class "$class" -e "$@" >/dev/null 2>&1
    i=0
    while [ "$i" -lt 20 ]; do
        hyprctl clients | grep -q "^[[:space:]]*class: $class\$" && break
        sleep 0.1
        i=$((i + 1))
    done
fi

"$(dirname "$0")/dispatch.sh" "hl.dsp.workspace.toggle_special(\"$class\")" \
    togglespecialworkspace "$class"

# Opened from a click, the mouse is on the bar, not over the dropdown, so
# focus would wait for it to move there (follow_mouse). If the toggle just
# showed it, hand it the keyboard at once.
if hyprctl monitors | grep -q "special workspace: .*[(:]$class)"; then
    "$(dirname "$0")/dispatch.sh" "hl.dsp.focus({ window = \"class:^($class)\$\" })" \
        focuswindow "class:^($class)\$"
fi
