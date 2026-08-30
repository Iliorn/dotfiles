#!/usr/bin/env bash

BAT1="/org/freedesktop/UPower/devices/battery_BAT1"
BAT0="/org/freedesktop/UPower/devices/battery_BAT0"

# ET ikonsaet til batteriet, plus et SELVSTAENDIGT lyn ved siden af naar der
# lades. Tidligere brugtes md-battery-charging-glyfferne (󰢛 󰢜 󰢝 ...), som har
# lynet skaaret ind i selve batteriet -- ved lav opladning er batteriet naesten
# tomt, og det der blev tilbage lignede en ambolt frem for et batteri. Lynet
# skal vaere der, men som sit eget tegn ved siden af, ikke inde i ikonet.
# Indeks = pct / 10.
ICONS=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
BOLT=󱐋

get_info() {
  upower -i "$1"
}

# Stikkontakten, ikke batteriets state: line_power-enheder er de eneste med
# "online", og den flipper med det samme naar opladeren tilsluttes. BAT1 kan
# ligge i "pending-charge" laenge efter, og det var det, der gav lag.
on_ac() {
  grep -qsx 1 /sys/class/power_supply/*/online
}

render() {
  local has_bat1 bat label info percent state p idx icon

  has_bat1=$(get_info "$BAT1" 2>/dev/null | grep -c "state:" || true)

  if [ "$has_bat1" -gt 0 ]; then
    # T480: dual battery — show whichever is discharging, prefer BAT1 otherwise
    if get_info "$BAT1" 2>/dev/null | grep -q "state:\s*discharging"; then
      bat="$BAT1"
      label="BAT1"
    elif get_info "$BAT0" 2>/dev/null | grep -q "state:\s*discharging"; then
      bat="$BAT0"
      label="BAT0"
    else
      bat="$BAT1"
      label="BAT1"
    fi
  else
    # Single battery (e.g. X220)
    bat="$BAT0"
    label=""
  fi

  info=$(get_info "$bat")

  percent=$(echo "$info" | awk '/percentage/ {print $2}')
  state=$(echo "$info" | awk '/state/ {print $2}')

  p=${percent%\%}
  idx=$((p / 10))
  [ "$idx" -gt 10 ] && idx=10

  icon="${ICONS[$idx]}"

  # Lynet haenger paa stikkontakten, ikke paa batteriets state -- samme grund
  # som on_ac() selv: BAT1 kan staa i "pending-charge" laenge efter at
  # opladeren er sat i.
  bolt=""
  on_ac && bolt="$BOLT"

  if [ "$state" = "fully-charged" ]; then
    # Fuldt batteri, ikke md-battery-charging-100: sidstnaevnte er en af de
    # glyffer med indbygget lyn som skulle vaek.
    icon="󰁹"
    percent="100%"
  fi

  if [ -n "$label" ]; then
    printf '%s%s %s (%s)\n' "$icon" "$bolt" "$percent" "$label" || exit 0
  else
    printf '%s%s %s\n' "$icon" "$bolt" "$percent" || exit 0
  fi
}

# Waybar laeser linjer lobende (modulet har ingen "interval"). Vi lytter paa
# EN langtlevende UPower-monitor og tegner paa hver event -- dvs. i samme
# oejeblik opladeren gaar i -- og ellers mindst hvert 30. sekund, saa
# procenten ogsaa folger med af sig selv.
#
# stdbuf -oL er ikke pynt. Uden den blokbuffrer upower sin stdout naar den
# skriver til et pipe, og saa ses en event foerst naar der er samlet 4 KB
# (~60 linjer) op. Det var praecis den forsinkelse paa 10-30 sekunder, det
# hele her handler om at fjerne -- maalt paa x220-1: udev og upower melder
# selv AC-skiftet paa under et halvt sekund.
render
exec 3< <(stdbuf -oL upower --monitor 2>/dev/null)
while :; do
  if read -r -t 30 -u 3 line; then
    # Alt andet end en "[tidsstempel] ..."-linje er velkomstteksten.
    case "$line" in
      \[*) ;;
      *) continue ;;
    esac
    # Events kommer i byger; toem resten, saa en bruger-handling giver en
    # gentegning og ikke fem.
    while read -r -t 0.25 -u 3 _; do :; done
  else
    # >128 = timeout (gentegn); alt andet = monitoren doede, saa lad
    # waybar starte os forfra via restart-interval.
    [ "$?" -le 128 ] && break
  fi
  render
done
