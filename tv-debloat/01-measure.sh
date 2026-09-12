#!/usr/bin/env bash
# Paso (b)/(f): toma las medidas. Ejecutalo con 'antes' y luego con 'despues'.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

LABEL="${1:-}"
[ -z "$LABEL" ] && die "uso: $0 <etiqueta>   (p.ej.  $0 antes   /   $0 despues)"
OUT="$DIR/measurements/$LABEL"
mkdir -p "$OUT"

echo "=== Midiendo ($LABEL) -> measurements/$LABEL/ ==="

# --- Identidad y version ---
{
  echo "fecha=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  for p in ro.product.model ro.product.manufacturer ro.build.product \
           ro.build.version.release ro.build.version.sdk ro.build.display.id; do
    echo "$p=$(ash getprop $p)"
  done
} > "$OUT/device.txt"

# --- RAM (lo que pide la regla 3) ---
ash dumpsys meminfo > "$OUT/meminfo.txt"
grep -E '^\s*(Total RAM|Free RAM|Used RAM|Lost RAM|ZRAM)' "$OUT/meminfo.txt" > "$OUT/ram-summary.txt" || true

# --- Paquetes ---
ash pm list packages -s | sed 's/^package://' | sort > "$OUT/packages-system.txt"
ash pm list packages -d | sed 's/^package://' | sort > "$OUT/packages-disabled.txt"
ash pm list packages -e | sed 's/^package://' | sort > "$OUT/packages-enabled.txt"
ash pm list packages -3 | sed 's/^package://' | sort > "$OUT/packages-thirdparty.txt"
ash pm list packages    | sed 's/^package://' | sort > "$OUT/packages-all.txt"

# --- Lanzador actual (para poder deshacer el cambio de home) ---
ash cmd package resolve-activity --brief -c android.intent.category.HOME \
  | tail -1 > "$OUT/home-activity.txt" || true

# --- Procesos en marcha, para ver qué se arranca solo ---
ash ps -A -o NAME 2>/dev/null | sort -u > "$OUT/processes.txt" || true

echo
echo "  Paquetes de sistema : $(wc -l < "$OUT/packages-system.txt")"
echo "  Ya desactivados     : $(wc -l < "$OUT/packages-disabled.txt")"
echo "  Instalados por ti   : $(wc -l < "$OUT/packages-thirdparty.txt")"
echo "  Lanzador actual     : $(cat "$OUT/home-activity.txt" 2>/dev/null)"
echo
cat "$OUT/ram-summary.txt" 2>/dev/null
echo
c_grn "Medida '$LABEL' guardada."
[ "$LABEL" = "antes" ] && echo "Siguiente:  ./02-triage.sh"
