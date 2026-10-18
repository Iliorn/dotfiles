#!/usr/bin/env bash
#
# Same look as powermenu.sh and the drun launcher: Nord, square, reverse-video
# selection. Kept in step by hand — -theme-str overrides a theme rather than
# inheriting from it.

op1="●  Performance"
op2="◐  Balanced"
op3="○  Power Saver"

options="$op1\n$op2\n$op3"

valgt=$(echo -e "$options" | rofi -dmenu -i -p "Profil" \
  -theme-str "window { width: 250px; border: 1px; border-radius: 0px; border-color: #4C566A; background-color: #2E3440; } \
                listview { lines: 3; scrollbar: false; padding: 0px; spacing: 0px; } \
                element { padding: 2px 14px; border-radius: 0px; text-color: #D8DEE9; } \
                element selected { background-color: #88C0D0; text-color: #2E3440; } \
                inputbar { enabled: false; }")

case "$valgt" in
*"Performance"*) powerprofilesctl set performance ;;
*"Balanced"*) powerprofilesctl set balanced ;;
*"Power Saver"*) powerprofilesctl set power-saver ;;
esac
