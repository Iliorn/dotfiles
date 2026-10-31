#!/usr/bin/env bash

# The glyph is the power profile, but the button opens systemmenu.sh (power,
# theme, network, bluetooth, sound), so the tooltip says "System" first.
profile=$(powerprofilesctl get)

if [ "$profile" == "performance" ]; then
  echo '{"text": "●", "tooltip": "System: Performance"}'
elif [ "$profile" == "balanced" ]; then
  # Denne er garanteret 50/50
  echo '{"text": "◐", "tooltip": "System: Balanced"}'
else
  echo '{"text": "○", "tooltip": "System: Power Saver"}'
fi
