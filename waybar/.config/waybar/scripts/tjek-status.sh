#!/bin/bash
# Waybar status module backed by tjek. tjek emits pretty-printed
# JSON; waybar's custom module parser requires single-line JSON, so
# pipe through `jq -c` to compact it. Also rewrite "x active" as
# "x task(s)" — the icon in waybar's format field already says what
# these are, so the word "active" only adds width.
#
# Shortened further (2026-11-01, the bar ran out of room): "1 overdue · 44
# active" becomes "44 · 1", with the overdue count in the theme's red
# (Pango markup; red read from the theme.css theme.sh renders, Nord's as the
# fallback). The full words stay in the tooltip.
red=$(sed -n 's/^@define-color red \(#[0-9A-Fa-f]\{6\}\);$/\1/p' "$HOME/.config/waybar/theme.css" 2>/dev/null)
tjek stats --format=waybar | jq -c --arg red "${red:-#BF616A}" '.text |= (split(" · ")
  | map(if test(" active$") then sub(" active$"; "")
        elif test(" overdue$") then "<span color=\"" + $red + "\">" + sub(" overdue$"; "") + "</span>"
        else . end)
  | reverse | join(" · "))'
