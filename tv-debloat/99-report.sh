#!/usr/bin/env bash
# Tabla antes/despues.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
A="$DIR/measurements/antes"; B="$DIR/measurements/despues"
[ -d "$A" ] || die "falta measurements/antes"
[ -d "$B" ] || die "falta measurements/despues (ejecuta ./01-measure.sh despues)"

kb() { grep -E "^\s*$1:" "$2/meminfo.txt" 2>/dev/null | head -1 \
       | grep -oE '[0-9,]+K' | head -1 | tr -d 'K,'; }
mb() { [ -n "${1:-}" ] && echo "$(( $1 / 1024 )) MB" || echo "n/d"; }

echo "| Medida             | Antes      | Despues    | Diferencia   |"
echo "|--------------------|------------|------------|--------------|"
for m in "Total RAM" "Free RAM" "Used RAM" "Lost RAM"; do
  a="$(kb "$m" "$A")"; b="$(kb "$m" "$B")"
  if [ -n "$a" ] && [ -n "$b" ]; then
    d=$(( (b - a) / 1024 )); sign=""; [ "$d" -gt 0 ] && sign="+"
    printf "| %-18s | %-10s | %-10s | %-12s |\n" "$m" "$(mb $a)" "$(mb $b)" "${sign}${d} MB"
  else
    printf "| %-18s | %-10s | %-10s | %-12s |\n" "$m" "${a:-n/d}" "${b:-n/d}" "n/d"
  fi
done
pa=$(wc -l < "$A/packages-enabled.txt"); pb=$(wc -l < "$B/packages-enabled.txt")
da=$(wc -l < "$A/packages-disabled.txt"); db=$(wc -l < "$B/packages-disabled.txt")
printf "| %-18s | %-10s | %-10s | %-12s |\n" "Paquetes activos"  "$pa" "$pb" "$((pb-pa))"
printf "| %-18s | %-10s | %-12s | %-12s |\n" "Paquetes desactiv." "$da" "$db" "+$((db-da))"
echo
echo "Desactivados en esta sesion: $(grep -cv '^#' "$DIR/disabled.txt" 2>/dev/null || echo 0)"
