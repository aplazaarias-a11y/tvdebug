#!/usr/bin/env bash
# Pasos (d) y (e): animaciones a la mitad y vaciar cachés.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

echo "=== Animaciones al 50% ==="
for k in window_animation_scale transition_animation_scale animator_duration_scale; do
  ash settings put global "$k" 0.5
  echo "  $k = $(ash settings get global $k)"
done

echo
echo "=== Vaciando cachés ==="
# OJO: 'pm trim-caches' EXIGE un tamaño. Sin el argumento falla con un
# 'Expected parameter' y no hace nada. Pedimos 999G para que libere todo.
ash pm trim-caches 999G && c_grn "  cachés vaciadas"

echo
c_grn "Listo. Ahora: adb reboot   y despues  ./01-measure.sh despues"
