#!/bin/sh
# Called by udiskie on every device event (udiskie/.config/udiskie/config.yml):
#   sd-detect.sh <event> <mount path>
# A camera card is a mounted filesystem with a DCIM folder; then the import
# window opens as a dropdown. Anything else (a USB stick, an unmount) is
# none of this script's business.
[ "$1" = device_mounted ] || exit 0
[ -d "$2/DCIM" ] || exit 0
exec "$(dirname "$0")/dropdown.sh" sd-import "$(dirname "$0")/sd-import.sh" "$2"
