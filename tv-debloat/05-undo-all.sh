#!/usr/bin/env bash
# EL BOTON DE PANICO: deshace absolutamente todo lo de esta sesion.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

echo "=== Reactivando todos los paquetes de disabled.txt ==="
if [ -f "$DIR/disabled.txt" ]; then
  while IFS='|' read -r pkg _; do
    pkg="$(echo "$pkg" | tr -d ' ')"
    [ -n "$pkg" ] && { ash pm enable "$pkg" | sed 's/^/  /'; }
  done < <(grep -v '^#' "$DIR/disabled.txt")
else
  echo "  (no hay disabled.txt)"
fi

echo "=== Animaciones a velocidad normal ==="
for k in window_animation_scale transition_animation_scale animator_duration_scale; do
  ash settings put global "$k" 1.0; echo "  $k = 1.0"
done

echo "=== Restaurando la pantalla de inicio anterior ==="
if [ -f "$DIR/previous-home.txt" ]; then
  H="$(tr -d '\r\n' < "$DIR/previous-home.txt")"
  [ -n "$H" ] && ash cmd package set-home-activity "$H" | sed 's/^/  /'
else
  # Sin previous-home.txt no se adivina el componente: se reactivan los dos
  # lanzadores posibles y que el sistema pregunte al pulsar INICIO.
  for cand in com.google.android.apps.tv.launcherx com.google.android.tvlauncher; do
    ash pm enable "$cand" 2>/dev/null | sed 's/^/  /'
  done
  echo "  (pulsa INICIO en el mando y elige la pantalla de inicio que quieras)"
fi

echo "=== Reiniciando ==="
"$ADB" -s "$TV" reboot
c_grn "Todo deshecho. La tele se esta reiniciando."
