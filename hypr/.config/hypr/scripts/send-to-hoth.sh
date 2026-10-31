#!/usr/bin/env bash
#
# Send a recent file to hoth, from the system menu: pick one of the newest
# files in Downloads, Pictures and Documents, then where it goes.
#
#   Drop       Taildrop. Everything sent to hoth that way lands in ~/Drop
#              (hoth's drop pipeline), which is the generic inbox.
#   Paperless  straight into hoth's ~/paperless/consume, which Paperless
#              watches: a receipt photographed or downloaded here is archived
#              and OCR'd without opening a browser.
#
# Newest first and only recent files, because what gets sent is almost always
# the thing that just arrived; anything older is a file manager's job.
#
# Colours and fonts come from rofi's minimal theme; -theme-str is layout only.

notify() { notify-send -a "hoth" "$@" 2>/dev/null || true; }

mapfile -t files < <(
  find ~/Downloads ~/Pictures ~/Documents -maxdepth 2 -type f \
    ! -name '.*' ! -name '*.part' ! -name '*.crdownload' \
    -printf '%T@\t%p\n' 2>/dev/null | sort -rn | head -40 | cut -f2-
)
[ "${#files[@]}" -gt 0 ] || { rofi -e "Ingen filer i Downloads, Pictures eller Documents"; exit 0; }

# Shown relative to home, so the folder says where it came from.
pick=$(printf '%s\n' "${files[@]/#$HOME\//}" | rofi -dmenu -i -format i -p "Send" \
  -theme-str "window { width: 700px; } listview { lines: 12; }")
[ -n "$pick" ] || exit 0
file="${files[$pick]}"
name=$(basename "$file")

where=$(printf '%s\n' "󰇚  Drop" "󰈙  Paperless" | rofi -dmenu -i -format i -p "$name" \
  -theme-str "window { width: 300px; } listview { lines: 2; } inputbar { enabled: false; }")

case "$where" in
0)
  if tailscale file cp "$file" hoth: 2>/dev/null; then
    notify "Sendt til hoth" "$name → ~/Drop"
  else
    notify -u critical "Kunne ikke sende" "$name (Taildrop til hoth fejlede)"
  fi
  ;;
1)
  if scp -q -o BatchMode=yes -o ConnectTimeout=5 "$file" hoth:paperless/consume/ 2>/dev/null; then
    notify "Sendt til Paperless" "$name"
  else
    notify -u critical "Kunne ikke sende" "$name (scp til hoth fejlede)"
  fi
  ;;
esac
