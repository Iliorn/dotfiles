#!/usr/bin/env bash
#
# Nord, square, reverse-video selection: the same look as the drun launcher
# in rofi/.local/share/rofi/themes/nord-minimal.rasi. The colours are written
# out rather than read from there because -theme-str overrides a theme, it
# does not inherit one — so these have to be kept in step by hand.
#
# `mainbox { children: [listview] }` is what hides the search field. It must
# stay on mainbox: the theme file explains why putting children: on window
# breaks exactly this.

# Definition af muligheder
op1="󰤄 Pause"
op2="󰍃 Log ud"
op3="󰑐 Genstart"
op4="󰐥 Sluk"

# Samlet liste til menuen
options="$op1\n$op2\n$op3\n$op4"

# Tæl antallet af linjer
num_options=$(echo -e "$options" | wc -l)

# Kør Rofi
valgt=$(echo -e "$options" | rofi -dmenu -i -p "System" \
  -theme-str "window { width: 250px; border: 1px; border-radius: 0px; border-color: #4C566A; background-color: #2E3440; } \
                mainbox { children: [listview]; background-color: transparent; } \
                listview { lines: $num_options; scrollbar: false; fixed-height: true; padding: 0px; spacing: 0px; background-color: transparent; } \
                element { padding: 2px 14px; border-radius: 0px; background-color: transparent; text-color: #D8DEE9; } \
                element selected { background-color: #88C0D0; text-color: #2E3440; }")

# Handling baseret på valg
case "$valgt" in
*"Pause"*)
  hyprlock & systemctl suspend
  ;;
*"Log ud"*)
  hyprctl dispatch exit
  ;;
*"Genstart"*)
  systemctl reboot
  ;;
*"Sluk"*)
  systemctl poweroff
  ;;
esac
