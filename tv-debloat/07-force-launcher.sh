#!/usr/bin/env bash
# Plan B del cambio de lanzador, para cuando 'set-home-activity' no funciona.
#
# En algunas teles (esta Philips entre ellas) el lanzador de Google se declara
# con priority=2 y gana siempre la resolucion, y 'cmd package
# set-home-activity' responde 'Success' sin registrar nada (se ve en que todos
# los candidatos siguen con preferredOrder=0). El unico camino es desactivar
# el lanzador de Google para que el otro quede como candidato de mas prioridad.
#
# Eso invierte el orden del plan original, asi que aqui la seguridad no la da
# el orden sino tres cosas:
#   1. Se EXIGE que FLauncher este registrado como HOME antes de tocar nada.
#   2. Se comprueba que existe un HOME de respaldo (FallbackHome).
#   3. Si tras desactivar el lanzador la pantalla de inicio NO pasa a ser
#      FLauncher, se REACTIVA automaticamente y se aborta.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

FL="me.efesser.flauncher"
KNOWN="com.google.android.apps.tv.launcherx com.google.android.tvlauncher"

home_now() {
  ash cmd package resolve-activity --brief \
    -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1
}
home_handlers() {
  ash cmd package query-activities -a android.intent.action.MAIN \
    -c android.intent.category.HOME 2>/dev/null | grep -oE 'packageName=[A-Za-z0-9_.]+' \
    | sed 's/packageName=//' | sort -u
}

echo "=== 1. Quien puede ser pantalla de inicio ==="
HANDLERS="$(home_handlers)"
[ -z "$HANDLERS" ] && die "No he podido listar los candidatos a HOME. No toco nada."
echo "$HANDLERS" | sed 's/^/  /'

echo
echo "=== 2. Comprobaciones antes de tocar nada ==="
if ! grep -qx "$FL" <<<"$HANDLERS"; then
  c_red "FLauncher NO esta registrado como pantalla de inicio."
  echo "Desactivar el lanzador de Google ahora SI dejaria la tele sin inicio."
  die "Abortado. Reinstala FLauncher y vuelve a intentarlo."
fi
c_grn "  FLauncher esta registrado como HOME"

if grep -qx "com.android.tv.settings" <<<"$HANDLERS"; then
  c_grn "  existe un HOME de respaldo (FallbackHome) por si acaso"
else
  c_yel "  AVISO: no veo HOME de respaldo. La red de seguridad es mas fina."
fi

BEFORE="$(home_now)"
case "$BEFORE" in */*) ;; *) die "No puedo leer el lanzador actual. No toco nada." ;; esac
CURPKG="${BEFORE%%/*}"
if [ "$CURPKG" = "$FL" ]; then
  c_grn "FLauncher ya es la pantalla de inicio. No hay nada que hacer."; exit 0
fi
GOOGLE=""
for k in $KNOWN; do [ "$CURPKG" = "$k" ] && GOOGLE="$k"; done
[ -z "$GOOGLE" ] && die "El lanzador actual ($CURPKG) no es de Google. No lo toco."
echo "  lanzador actual: $GOOGLE"
echo "$BEFORE" > "$DIR/previous-home.txt"

echo
echo "=== 3. Desactivando $GOOGLE ==="
OUT="$(ash pm disable-user --user 0 "$GOOGLE" 2>&1)"
if ! grep -qi 'new state: disabled' <<<"$OUT"; then
  die "No se ha podido desactivar: $OUT"
fi
c_grn "  desactivado"
sleep 3

echo
echo "=== 4. ¿Ha tomado el relevo FLauncher? ==="
NOW="$(home_now)"
echo "  home ahora: $NOW"
case "$NOW" in
  "$FL"/*)
    c_grn "SI. FLauncher es la pantalla de inicio."
    printf '%-55s | %-16s | %s\n' "$GOOGLE" "launcher" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$DIR/disabled.txt"
    ;;
  *)
    c_red "NO. Deshaciendo ahora mismo para no dejarte sin pantalla de inicio."
    ash pm enable "$GOOGLE" | sed 's/^/  /'
    die "Revertido. La tele sigue con $GOOGLE. Dime que ha salido y buscamos otra via."
    ;;
esac

echo
c_yel "=== 5. Reinicia y comprueba ==="
echo "  adb -s $TV reboot"
echo
echo "Tras el reinicio: cuadricula con tus apps, sin filas de recomendaciones."
echo
echo "Si algo va mal, esto lo devuelve todo a como estaba:"
echo "  adb connect $TV && adb -s $TV shell pm enable $GOOGLE && adb -s $TV reboot"
