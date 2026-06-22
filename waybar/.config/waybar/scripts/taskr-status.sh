#!/bin/bash
# Waybar status module backed by taskr. taskr's own --format=waybar
# emits {class, text, tooltip} JSON that Waybar consumes directly.
exec taskr stats --format=waybar
