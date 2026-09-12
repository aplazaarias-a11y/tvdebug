#!/usr/bin/env bash
# Cambia la pantalla de inicio a FLauncher.
# El orden importa: NO se desactiva el lanzador de Google hasta haber
# comprobado que FLauncher esta instalado Y es el home por defecto.
# Si se hace al contrario, la tele arranca con la pantalla en negro.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

FL="me.efesser.flauncher"
GOOGLE="com.google.android.apps.tv.launcherx"

echo "=== 1. ¿Esta FLauncher instalado? ==="
if ! ash pm list packages | grep -q "^package:${FL}$"; then
  c_red "FLauncher NO esta instalado."
  echo
  echo "Instalalo tu primero (no lo hago yo por ti, es una descarga en tu tele):"
  echo "  Tele > Play Store > buscar 'FLauncher' > Instalar"
  echo "  (gratis, codigo abierto, solo una cuadricula con tus apps)"
  echo
  echo "Cuando este, vuelve a ejecutar este script."
  exit 1
fi
c_grn "FLauncher instalado."

echo
echo "=== 2. Cual es el lanzador actual ==="
BEFORE="$(ash cmd package resolve-activity --brief -c android.intent.category.HOME | tail -1)"
echo "  $BEFORE"
echo "$BEFORE" > "$DIR/previous-home.txt"
echo "  (guardado en previous-home.txt para poder deshacerlo)"

echo
echo "=== 3. Abriendo FLauncher una vez ==="
ash monkey -p "$FL" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 \
  || ash am start -n "${FL}/${FL}.MainActivity" >/dev/null 2>&1 || true
sleep 3

echo
echo "=== 4. Poniendolo como pantalla de inicio ==="
ash cmd package set-home-activity "${FL}/${FL}.MainActivity" 2>&1 | sed 's/^/  /'
sleep 2
NOW="$(ash cmd package resolve-activity --brief -c android.intent.category.HOME | tail -1)"
echo "  home actual: $NOW"

if ! grep -q "$FL" <<<"$NOW"; then
  c_red "FLauncher NO ha quedado como home. NO desactivo nada."
  echo
  echo "Hazlo a mano y es igual de valido:"
  echo "  1. Pulsa HOME en el mando."
  echo "  2. Sale 'Usar otra aplicacion' / 'Seleccionar pantalla de inicio'."
  echo "  3. Elige FLauncher y marca 'Siempre'."
  echo "  4. Repite este script para que lo verifique."
  exit 2
fi
c_grn "FLauncher es ya la pantalla de inicio."

echo
echo "=== 5. Ahora SI es seguro desactivar el lanzador de Google ==="
# Este es el unico sitio donde se salta la proteccion de NEVER-DISABLE.txt,
# y solo despues de haber verificado el paso 4.
OUT="$(ash pm disable-user --user 0 "$GOOGLE" 2>&1)"
if grep -qi 'new state: disabled' <<<"$OUT"; then
  c_grn "  desactivado  $GOOGLE"
  printf '%-55s | %-16s | %s\n' "$GOOGLE" "launcher" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$DIR/disabled.txt"
else
  c_yel "  no se ha podido desactivar -> $OUT"
fi

echo
c_yel "=== 6. Reinicia y comprueba ==="
echo "  adb -s $TV reboot"
echo
echo "Tras el reinicio la tele debe arrancar en FLauncher (cuadricula de apps,"
echo "sin filas de 'recomendado para ti' ni anuncios)."
echo
echo "Si arranca en NEGRO:  adb -s $TV shell pm enable $GOOGLE  &&  adb -s $TV reboot"
