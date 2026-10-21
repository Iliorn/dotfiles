#!/usr/bin/env bash
#
# Colours and fonts come from rofi/.local/share/rofi/themes/nord-minimal.rasi,
# which config.rasi loads for every rofi run, dmenu included. -theme-str below
# carries layout only.
#
# Enter copies the entry back; Alt+Delete (rofi's kb-custom-1, exit status 10)
# removes it from the history and reopens the list.

while true; do
  valgt=$(cliphist list | rofi -dmenu -i -p "Clipboard" \
    -kb-custom-1 "Alt+Delete" \
    -theme-str "window { width: 700px; } \
                listview { lines: 10; fixed-height: true; }")
  status=$?

  case $status in
  0)
    printf '%s' "$valgt" | cliphist decode | wl-copy
    break
    ;;
  10)
    printf '%s' "$valgt" | cliphist delete
    ;;
  *)
    break
    ;;
  esac
done
