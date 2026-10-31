#!/bin/sh
# `hyprctl dispatch` for both config languages, while the laptops move from
# hyprland.conf to hyprland.lua.
#
# With the Lua config loaded, `hyprctl dispatch X` runs `hl.dispatch(X)`, so
# the old `dispatch workspace 1` is a Lua syntax error. A Hyprland still
# running hyprland.conf answers "Invalid dispatcher" to the Lua form instead.
# So: the Lua form first, the old one only if that was not accepted. Either
# miss is a harmless error, never a different action.
#
# Never hand the Lua form a bare string: hl.dsp.dpms("on") is read as TOGGLE,
# because only a table with action = "on"/"off" is parsed (verified on 0.57,
# where it switched the panel off).
#
# Usage: dispatch.sh '<Lua dispatcher>' <old dispatcher> [args...]
# Delete this, and call hyprctl dispatch with the Lua form directly, once the
# .conf files are gone.
lua=$1
shift
[ "$(hyprctl dispatch "$lua" 2>&1)" = ok ] || hyprctl dispatch "$@"
