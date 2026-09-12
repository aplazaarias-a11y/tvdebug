#!/usr/bin/env bash
# Cambia la pantalla de inicio a FLauncher.
# El orden importa: NO se desactiva el lanzador de Google hasta haber
# comprobado que FLauncher esta instalado Y es ya el home por defecto.
# Al contrario, la tele arranca con la pantalla en negro.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

FL="me.efesser.flauncher"
# Los dos unicos lanzadores de Google que se pueden desactivar aqui. Cualquier
# otro paquete (un lanzador del fabricante, otro de terceros) se deja en paz.
KNOWN="com.google.android.apps.tv.launcherx com.google.android.tvlauncher"

home_now() {
  ash cmd package resolve-activity --brief \
    -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1
}

echo "=== 1. ¿Esta FLauncher instalado? ==="
if ! ash pm list packages | grep -q "^package:${FL}$"; then
  c_red "FLauncher NO esta instalado."
  echo
  echo "Instalalo tu primero, en la tele:"
  echo "  Play Store > buscar 'FLauncher' > Instalar"
  echo "Luego vuelve a ejecutar este script."
  exit 1
fi
c_grn "FLauncher instalado."

echo
echo "=== 2. Cual es el lanzador actual ==="
BEFORE="$(home_now)"
case "$BEFORE" in
  */*) echo "  $BEFORE" ;;
  *)   die "No he podido leer el lanzador actual (respuesta: '$BEFORE'). No toco nada." ;;
esac

# El que hay que desactivar es EL QUE ESTA ACTIVO, no "el primero de una
# lista de candidatos": si estan instalados los dos lanzadores de Google,
# elegir por orden desactiva el que no se usa y deja los anuncios intactos.
CURPKG="${BEFORE%%/*}"
GOOGLE=""
for k in $KNOWN; do [ "$CURPKG" = "$k" ] && GOOGLE="$k"; done

if [ "$CURPKG" = "$FL" ]; then
  c_yel "FLauncher ya es la pantalla de inicio."
elif [ -z "$GOOGLE" ]; then
  die "El lanzador actual ($CURPKG) no es de Google. No lo toco: dime cual es."
else
  echo "  lanzador de Google a desactivar al final: $GOOGLE"
fi
echo "$BEFORE" > "$DIR/previous-home.txt"
echo "  (guardado en previous-home.txt para poder deshacerlo)"

echo
echo "=== 3. Abriendo FLauncher una vez ==="
ash monkey -p "$FL" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 \
  || ash am start -n "${FL}/${FL}.MainActivity" >/dev/null 2>&1 || true
sleep 3

echo
echo "=== 4. Poniendolo como pantalla de inicio ==="
# Se intenta averiguar su actividad HOME real; si no se puede, se usa la
# conocida. Si ninguna funciona, el paso 4 falla y no se desactiva nada.
FLACT="$(ash cmd package query-activities -a android.intent.action.MAIN \
          -c android.intent.category.HOME 2>/dev/null \
          | grep -oE "${FL}/[A-Za-z0-9_.]+" | head -1)"
[ -z "$FLACT" ] && FLACT="${FL}/${FL}.MainActivity"
echo "  usando: $FLACT"
ash cmd package set-home-activity "$FLACT" 2>&1 | sed 's/^/  /'
sleep 2
NOW="$(home_now)"
echo "  home actual: $NOW"

case "$NOW" in
  "$FL"/*) c_grn "FLauncher es ya la pantalla de inicio." ;;
  *)
    c_red "FLauncher NO ha quedado como home. NO desactivo nada."
    echo
    echo "Hazlo a mano, es igual de valido:"
    echo "  1. Pulsa INICIO en el mando."
    echo "  2. Sale 'Usar otra aplicacion' / 'Seleccionar pantalla de inicio'."
    echo "  3. Elige FLauncher y marca 'Siempre'."
    echo "  4. Repite este script para que lo verifique."
    exit 2 ;;
esac

if [ -z "$GOOGLE" ]; then
  echo; c_yel "No hay lanzador de Google que desactivar. Hecho."; exit 0
fi

echo
echo "=== 5. Ahora SI es seguro desactivar el lanzador de Google ==="
# Unico sitio donde se salta NEVER-DISABLE.txt a proposito, y solo despues
# de que el paso 4 haya verificado el cambio.
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
echo "Tras el reinicio la tele debe arrancar en FLauncher: una cuadricula con"
echo "tus apps, sin filas de 'recomendado para ti' ni anuncios."
echo
echo "Si arranca en NEGRO:"
echo "  adb connect $TV && adb -s $TV shell pm enable $GOOGLE && adb -s $TV reboot"
