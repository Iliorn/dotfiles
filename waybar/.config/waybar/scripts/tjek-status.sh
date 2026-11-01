#!/bin/bash
# Waybar status module backed by tjek. tjek emits pretty-printed
# JSON; waybar's custom module parser requires single-line JSON, so
# pipe through `jq -c` to compact it. Also rewrite "x active" as
# "x task(s)" — the icon in waybar's format field already says what
# these are, so the word "active" only adds width.
#
# Shortened further (2026-11-01, the bar ran out of room): "1 overdue · 44
# active" becomes "44 · 1!". The count comes first, overdue is marked with !
# (the module also turns red then), and the full words stay in the tooltip.
tjek stats --format=waybar | jq -c '.text |= (split(" · ")
  | map(if test(" active$") then sub(" active$"; "")
        elif test(" overdue$") then sub(" overdue$"; "!")
        else . end)
  | reverse | join(" · "))'
