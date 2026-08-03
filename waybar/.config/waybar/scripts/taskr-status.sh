#!/bin/bash
# Waybar status module backed by taskr. taskr emits pretty-printed
# JSON; waybar's custom module parser requires single-line JSON, so
# pipe through `jq -c` to compact it. Also rewrite "x active" as
# "x task(s)" — the icon in waybar's format field already says what
# these are, so the word "active" only adds width.
taskr stats --format=waybar | jq -c '.text |= (if startswith("1 ") then sub(" active$"; " task") else sub(" active$"; " tasks") end)'
