#!/bin/bash
# Waybar status module backed by taskr. taskr emits pretty-printed
# JSON; waybar's custom module parser requires single-line JSON, so
# pipe through `jq -c` to compact it. Also expand "x active" to
# "x active task(s)" for the status text, pluralized by count.
taskr stats --format=waybar | jq -c '.text |= (if startswith("1 ") then sub("active$"; "active task") else sub("active$"; "active tasks") end)'
