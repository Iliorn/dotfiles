#!/usr/bin/env bash
#
# Colours and fonts come from rofi/.local/share/rofi/themes/nord-minimal.rasi,
# which config.rasi loads for every rofi run, dmenu included. -theme-str below
# carries layout only.
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
  -theme-str "window { width: 250px; } \
                mainbox { children: [listview]; } \
                listview { lines: $num_options; fixed-height: true; }")

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
