#!/usr/bin/env bash
# The SD import window (opened by sd-detect.sh when a camera card mounts):
#
#   sd-import.sh <mount path>
#
# Finds the files on the card hoth has not had yet, copies them to hoth's
# inbox (~/foto-indbakke/<time>-<card>/), checks every one with sha256 on
# hoth, records them as imported, and only then offers to delete them from
# the card. Hoth sorts and develops from the inbox (the photo chain's next
# steps). Step 1 of the SD -> Immich workflow, 2026-11-01.
#
# "New" = name + size not in hoth's ~/.local/state/foto-import/seen.tsv, so
# a card imported before only offers what was shot since.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

mp=${1:?mount path}
hoth=${FOTO_HOTH:-hoth}
label=$(basename "$mp")
stamp=$(date +%Y%m%d-%H%M%S)
# The card's label goes into a path on hoth: only safe characters (a Nikon
# card is "NIKON Z6II", and the space broke the remote commands in testing).
inbox="foto-indbakke/$stamp-$(printf '%s' "$label" | tr -c 'A-Za-z0-9._-' '_')"
q_inbox=$(printf '%q' "$inbox")
seen=".local/state/foto-import/seen.tsv"

pause() { read -rp "  Enter lukker. " _; exit "${1:-0}"; }

# Done with the card: Enter unmounts it (and powers it off where the reader
# allows), so it can be pulled straight out (Mark, 2026-11-03). Unmounted,
# udiskie does not mount it again until it is put back in.
eject() {
    read -rp "  Enter skubber kortet ud · Esc lader det sidde " _ || exit 0
    dev=$(findmnt -n -o SOURCE --target "$mp")
    cd / || exit 1
    sync
    if udisksctl unmount -b "$dev" >/dev/null 2>&1; then
        udisksctl power-off -b "$dev" >/dev/null 2>&1 || true
        printf '  Kortet er skubbet ud og kan tages ud.\n'
        sleep 2
        exit 0
    fi
    printf '  Kunne ikke skubbe kortet ud (er en fil på det åben?).\n'
    pause 1
}

cd "$mp" || { echo "  Kortet ($mp) er ikke tilgængeligt."; pause 1; }

# Photos and videos only, relative paths, NUL-separated (names may hold spaces).
mapfile -d '' all < <(find DCIM -type f \( -iname '*.nef' -o -iname '*.nrw' -o -iname '*.jpg' \
    -o -iname '*.jpeg' -o -iname '*.dng' -o -iname '*.heic' -o -iname '*.mov' -o -iname '*.mp4' \
    -o -iname '*.tif' -o -iname '*.tiff' \) -print0 | sort -z)

printf '\n  SD-kort: %s\n' "$label"
if ! seenlist=$(ssh -o BatchMode=yes -o ConnectTimeout=8 "$hoth" "cat $seen 2>/dev/null; true"); then
    printf '\n  hoth svarer ikke, så der kan ikke importeres nu.\n'
    pause 1
fi

new=()
for f in "${all[@]}"; do
    key="$(basename "$f")	$(stat -c %s "$f")"
    grep -qxF -- "$key" <<<"$seenlist" || new+=("$f")
done

printf '  %d filer på kortet, %d nye\n\n' "${#all[@]}" "${#new[@]}"
if [ "${#new[@]}" -eq 0 ]; then
    printf '  Intet nyt at importere.\n'
    eject
fi
read -rp "  Enter = importér til hoth · Esc = ikke nu " _ || exit 0

ssh -o BatchMode=yes "$hoth" "mkdir -p ~/$q_inbox ~/.local/state/foto-import" || { echo "  Kunne ikke oprette indbakken på hoth."; pause 1; }
printf '\n  Kopierer %d filer ...\n' "${#new[@]}"
if ! printf '%s\0' "${new[@]}" | rsync -a --from0 --files-from=- --info=progress2 ./ "$hoth:$inbox/"; then
    printf '\n  Kopieringen fejlede. Intet er slettet fra kortet; prøv igen.\n'
    pause 1
fi

printf '\n  Kontrollerer på hoth (sha256) ...\n'
sums=$(printf '%s\0' "${new[@]}" | xargs -0 sha256sum)
if ! ssh -o BatchMode=yes "$hoth" "cd ~/$q_inbox && sha256sum --quiet -c -" <<<"$sums"; then
    printf '\n  Kontrollen fejlede for filerne ovenfor. Intet er slettet fra kortet.\n'
    pause 1
fi

keys=$(for f in "${new[@]}"; do printf '%s\t%s\n' "$(basename "$f")" "$(stat -c %s "$f")"; done)
ssh -o BatchMode=yes "$hoth" "cat >> $seen" <<<"$keys"
# Hand over: .done marks the batch complete and checked, and foto-sort
# (the ansible repo's roles/foto_sort) files it into ~/Billeder and develops
# any negatives; a push says when it is done.
ssh -o BatchMode=yes "$hoth" "touch ~/$q_inbox/.done && systemctl --user start --no-block foto-sort.service"
printf '\n  %d filer importeret og kontrolleret.\n' "${#new[@]}"
printf '  hoth sorterer dem nu og fremkalder eventuelle negativer; der kommer en push, når det er færdigt.\n'

read -rp "  Slet de importerede filer fra kortet? [j/N] " answer || exit 0
case "$answer" in
j|J)
    printf '%s\0' "${new[@]}" | xargs -0 rm -f --
    sync
    printf '  Slettet fra kortet.\n' ;;
*)  printf '  Kortet er urørt.\n' ;;
esac
eject
