#!/bin/bash
# Waybar status module backed by taskr. taskr emits pretty-printed
# JSON; waybar's custom module parser requires single-line JSON, so
# pipe through `jq -c` to compact it.
taskr stats --format=waybar | jq -c .
