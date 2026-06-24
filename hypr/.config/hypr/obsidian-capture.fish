#!/usr/bin/env fish
read --prompt-str "→ " note
if test -n "$note"
    set today (date +%Y-%m-%d)
    set path "A. Personligt/0 - Generelt/Daglige noter/$today.md"
    set fullpath "$HOME/Documents/Obsidian Vault/$path"
    if not test -f $fullpath
        obsidian create path="$path"
    end
    set time (date +%H:%M)
    obsidian append path="$path" content="- $time: $note"
end
