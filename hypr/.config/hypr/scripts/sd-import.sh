#!/usr/bin/env bash
# The SD import window (opened by sd-detect.sh when a camera card mounts):
#
#   sd-import.sh <mount path>
#
# Finds the files on the card hoth has not had yet, copies them to hoth's
# inbox in parts of 20 (~/foto-indbakke/<time>-<card>-001/, -002/ ...),
# checks every one with sha256 on hoth, records them as imported and hands
# each part over as it is done; only then offers to delete them from the
# card, and Enter ejects it. Hoth sorts and develops from the inbox (the photo chain's next
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

# In parts of $chunk files (Mark, 2026-11-03: a big card should not wait for
# its last file before hoth starts): each part is copied, checked and handed
# over on its own, so hoth sorts and develops while the rest is copied, and
# Immich shows them as they come. A failed part stops there; the parts before
# it are imported and recorded, the rest stays on the card for next time.
chunk=${FOTO_IMPORT_CHUNK:-20}
total=${#new[@]}
parts=$(( (total + chunk - 1) / chunk ))
imported=()
printf '\n  Kopierer %d filer i %d dele ...\n' "$total" "$parts"
for ((i = 0; i < total; i += chunk)); do
    part=("${new[@]:i:chunk}")
    n=$(( i / chunk + 1 ))
    dir="$inbox-$(printf '%03d' "$n")"
    q_dir=$(printf '%q' "$dir")
    printf '\n  Del %d/%d (%d filer)\n' "$n" "$parts" "${#part[@]}"
    ssh -o BatchMode=yes "$hoth" "mkdir -p ~/$q_dir ~/.local/state/foto-import" || { echo "  Kunne ikke oprette indbakken på hoth."; break; }
    if ! printf '%s\0' "${part[@]}" | rsync -a --from0 --files-from=- --info=progress2 ./ "$hoth:$dir/"; then
        printf '\n  Kopieringen fejlede i del %d. Resten er urørt på kortet; prøv igen.\n' "$n"
        break
    fi
    sums=$(printf '%s\0' "${part[@]}" | xargs -0 sha256sum)
    if ! ssh -o BatchMode=yes "$hoth" "cd ~/$q_dir && sha256sum --quiet -c -" <<<"$sums"; then
        printf '\n  Kontrollen fejlede i del %d (filerne ovenfor). Intet er slettet fra kortet.\n' "$n"
        break
    fi
    keys=$(for f in "${part[@]}"; do printf '%s\t%s\n' "$(basename "$f")" "$(stat -c %s "$f")"; done)
    ssh -o BatchMode=yes "$hoth" "cat >> $seen" <<<"$keys"
    # Hand over: .done marks the part complete and checked, and foto-sort
    # (the ansible repo's roles/foto_sort) files it into ~/Billeder and
    # develops any negatives. If foto-sort is already busy with an earlier
    # part, the start does nothing; the pending file makes it go round once
    # more when it finishes, so this part is not left for the timer.
    ssh -o BatchMode=yes "$hoth" "touch ~/$q_dir/.done ~/.local/state/foto-import/juster-pending && systemctl --user start --no-block foto-sort.service"
    imported+=("${part[@]}")
done
if [ "${#imported[@]}" -eq 0 ]; then
    pause 1
fi
new=("${imported[@]}")
printf '\n  %d af %d filer importeret og kontrolleret.\n' "${#new[@]}" "$total"
printf '  hoth sorterer og fremkalder dem løbende; der kommer en push, når det er færdigt.\n\n'

read -rp "  Slet de importerede filer fra kortet? [j/N] " answer || exit 0
case "$answer" in
j|J)
    printf '%s\0' "${new[@]}" | xargs -0 rm -f --
    sync
    printf '  Slettet fra kortet.\n' ;;
*)  printf '  Kortet er urørt.\n' ;;
esac
eject
