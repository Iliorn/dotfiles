#!/usr/bin/env bash
#
# Colours and fonts come from the nord-minimal rofi theme, which config.rasi
# loads for every run; -theme-str below carries layout only.

op1="●  Performance"
op2="◐  Balanced"
op3="○  Power Saver"

options="$op1\n$op2\n$op3"

valgt=$(echo -e "$options" | rofi -dmenu -i -p "Profil" \
  -theme-str "window { width: 250px; } \
                listview { lines: 3; } \
                inputbar { enabled: false; }")

case "$valgt" in
*"Performance"*) powerprofilesctl set performance ;;
*"Balanced"*) powerprofilesctl set balanced ;;
*"Power Saver"*) powerprofilesctl set power-saver ;;
esac
