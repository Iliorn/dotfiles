#!/usr/bin/env bash
#
# Notification history (super+N): dunst's history, newest first, one line each:
#   HH:MM  appname  summary — body
# in rofi, the same TUI style as systemmenu.sh and clipmenu.sh. The search
# field stays: unlike those menus this list can be long, and finding "that
# build failed message" by typing is the point.
#
# Enter closes the menu and copies the body (or the summary if there is none)
# to the clipboard; nothing else happens to the notification.
#
# python3, not jq: dunst stamps a notification with the MONOTONIC clock
# (microseconds since boot, not since 1970), and only python can read that
# clock to turn the stamp into a wall-clock time. python3 is already needed
# by screens-watch.py, so this adds no dependency.
#
# Fonts and colours come from the rofi theme, as in the other menus;
# -theme-str carries layout only.

# One snapshot, used for both the list and the lookup after the pick, so the
# row number cannot point at a different notification if a new one arrives
# while the menu is open.
hist=$(dunstctl history 2>/dev/null)

# Prints the rows ("list"), or the text to copy for row N ("copy" N).
render() {
  printf '%s' "$hist" | python3 -c '
import html, json, re, sys, time

def field(n, key):
    return n.get(key, {}).get("data", "")

def plain(text):
    # dunst keeps Pango markup and newlines; a one-line menu wants neither.
    text = re.sub(r"<[^>]+>", "", text)
    return " ".join(html.unescape(text).split())

def trim(text, width):
    return text if len(text) <= width else text[: width - 1] + "…"

try:
    notes = json.load(sys.stdin)["data"][0]
except (ValueError, KeyError, IndexError):
    notes = []
notes.sort(key=lambda n: field(n, "timestamp"), reverse=True)

if sys.argv[1] == "copy":
    n = notes[int(sys.argv[2])]
    print(plain(field(n, "body")) or plain(field(n, "summary")))
    sys.exit()

boot = time.time() - time.clock_gettime(time.CLOCK_MONOTONIC)
apps = [trim(plain(field(n, "appname")), 14) for n in notes]
pad = max(map(len, apps), default=0)
for n, app in zip(notes, apps):
    clock = time.strftime("%H:%M", time.localtime(boot + field(n, "timestamp") / 1e6))
    summary, body = plain(field(n, "summary")), plain(field(n, "body"))
    text = f"{summary} — {body}" if body else summary
    print(f"{clock}  {app.ljust(pad)}  {trim(text, 120)}")
' "$@"
}

rows=$(render list)

if [ -z "$rows" ]; then
  exec rofi -e "Ingen notifikationer i historikken"
fi

pick=$(echo "$rows" | rofi -dmenu -i -format i -p "Notifikationer" \
  -theme-str "window { width: 800px; } \
                listview { lines: 10; fixed-height: true; }")
[ -n "$pick" ] || exit 0

render copy "$pick" | wl-copy
