#!/usr/bin/env bash
# System -> Foto: correct a developed negative from the menu (2026-11-02).
#
#   rolls (newest first) -> frames with previews -> lysere / mørkere /
#   varmere / koldere / drej / tilbage til automatisk / åbn filen i hx
#
# Every choice writes the frame's line in the roll's justering.txt on hoth
# (foto-juster, from ansible's roles/foto_sort) and starts foto-sort there,
# which develops that frame again; a push says when it is done. The file
# stays the truth: the menu only edits it, and hx can too.
#
# Previews are made on hoth and kept in ~/.cache/foto-juster/<day>/, fetched
# again only when a frame has been developed anew.
set -uo pipefail

hoth=${FOTO_HOTH:-hoth}
cache=~/.cache/foto-juster

fj() { ssh -o BatchMode=yes -o ConnectTimeout=8 "$hoth" "~/.local/bin/foto-juster $(printf '%q ' "$@")"; }
say() { notify-send -a "Foto" "$@" 2>/dev/null || true; }

rolls=$(fj ruller) || { say "hoth svarer ikke" "Foto-menuen kan ikke hente rullerne."; exit 1; }
[ -n "$rolls" ] || { say "Ingen negativer endnu" "Der er ingen fremkaldte ruller på hoth."; exit 0; }

# Same look as systemmenu.sh: fonts and colours from the rofi theme, layout
# here. The search field stays on in the lists, so typing "174" finds it;
# -format i answers with the row in the original list.
rows=$(awk -F'\t' '{ printf "%s   %3d billeder%s\n", $1, $2, ($3 > 0 ? "  · " $3 " justeret" : "") }' <<<"$rolls")
pick=$(rofi -dmenu -i -format i -p "Foto" \
    -theme-str "window { width: 380px; } listview { lines: 10; }" <<<"$rows") || exit 0
[ -n "$pick" ] || exit 0
day=$(sed -n "$((pick + 1))p" <<<"$rolls" | cut -f1)

actions="󰃠  Lysere ⅓
󰃞  Mørkere ⅓
󰖨  Varmere
󰜗  Koldere
󰑧  Drej 90° med uret
󰦛  Tilbage til automatisk
󰏫  Åbn justering.txt i hx"
ops=(lysere mørkere varmere koldere drej auto fil)

# One frame: the actions, again and again until Esc (back to the frames).
adjust() {
    local name=$1 cur=$2 a op
    while :; do
        a=$(rofi -dmenu -format i -p "$name" -mesg "Nu: ${cur:-automatisk}" \
            -theme-str "window { width: 380px; } listview { lines: 7; } inputbar { enabled: false; }" \
            <<<"$actions") || return 0
        [ -n "$a" ] || return 0
        op=${ops[$a]}
        if [ "$op" = fil ]; then
            # A plain terminal, not a dropdown: a dropdown's Esc closes the
            # window, and helix needs its Esc.
            path=$(fj fil "$day") || { say "hoth svarer ikke"; return 0; }
            setsid -f alacritty --class foto-juster -e ssh -t "$hoth" "hx $(printf '%q' "$path")" >/dev/null 2>&1
            exit 0
        fi
        cur=$(fj juster "$day" "$name" "$op") || { say "Kunne ikke gemme" "$name: hoth svarede ikke."; return 0; }
        say "$name: ${cur:-automatisk}" "hoth fremkalder billedet igen; der kommer en push, når det er færdigt."
    done
}

row=0
while :; do
    dir=$(fj thumbs "$day") && mkdir -p "$cache/$day" &&
        rsync -a --delete "$hoth:$dir/" "$cache/$day/" ||
        say "Ingen forhåndsvisninger" "Kunne ikke hente dem fra hoth; listen virker uden."
    list=$(fj billeder "$day") || { say "hoth svarer ikke"; exit 1; }
    pick=$(while IFS=$'\t' read -r name adj; do
        printf '%s%s\0icon\x1f%s\n' "$name" "${adj:+   · $adj}" "$cache/$day/$name.jpg"
    done <<<"$list" | rofi -dmenu -i -format i -show-icons -selected-row "$row" -p "$day" \
        -theme-str "window { width: 560px; } listview { lines: 5; } element-icon { size: 5em; }") || exit 0
    [ -n "$pick" ] || exit 0
    row=$pick
    IFS=$'\t' read -r name adj < <(sed -n "$((pick + 1))p" <<<"$list")
    adjust "$name" "$adj"
done
