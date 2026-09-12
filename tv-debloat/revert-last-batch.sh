#!/usr/bin/env bash
# Regla 7: reactiva SOLO la ultima tanda.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device
LOG="$DIR/disabled.txt"
[ -f "$LOG" ] || die "no hay disabled.txt, nada que deshacer"

LAST="$(grep -v '^#' "$LOG" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | tail -1)"
[ -z "$LAST" ] && die "disabled.txt esta vacio"
echo "=== Reactivando la ultima tanda: $LAST ==="

N=0
while IFS='|' read -r pkg tanda rest; do
  pkg="$(echo "$pkg" | tr -d ' ')"; tanda="$(echo "$tanda" | tr -d ' ')"
  [ "$tanda" = "$LAST" ] || continue
  OUT="$(ash pm enable "$pkg" 2>&1)"
  grep -qi 'new state: enabled' <<<"$OUT" && c_grn "  reactivado  $pkg" || c_red "  fallo  $pkg -> $OUT"
  N=$((N+1))
done < <(grep -v '^#' "$LOG")

# quita esa tanda del registro
grep -v "| *${LAST} *|" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
echo
echo "$N paquetes reactivados y borrados de disabled.txt."
c_yel "Reinicia la tele (adb reboot) y comprueba que vuelve a funcionar."
echo "Luego desactivamos de uno en uno para encontrar al culpable."
