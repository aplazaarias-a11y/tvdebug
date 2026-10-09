#!/usr/bin/env bash
# ¿Por que una app instalada no sale en FLauncher?
#
# Android distingue dos tipos de icono de lanzamiento:
#   LEANBACK_LAUNCHER -> app de televisor. Los lanzadores de TV la muestran.
#   LAUNCHER          -> app de movil. Los lanzadores de TV la OCULTAN por
#                        defecto, aunque este perfectamente instalada.
# Este script solo lee. No cambia nada.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

handlers() {
  ash cmd package query-activities -a android.intent.action.MAIN -c "$1" 2>/dev/null \
    | grep -oE 'packageName=[A-Za-z0-9_.]+' | sed 's/packageName=//' | sort -u
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ash pm list packages -3 | sed 's/^package://' | tr -d '\r' | sort -u > "$TMP/mine"
handlers android.intent.category.LEANBACK_LAUNCHER > "$TMP/tv"
handlers android.intent.category.LAUNCHER          > "$TMP/phone"

echo "=== Apps que has instalado tu: $(wc -l < "$TMP/mine" | tr -d ' ') ==="
echo

echo "--- SE VEN en FLauncher (son apps de televisor) ---"
comm -12 "$TMP/mine" "$TMP/tv" > "$TMP/ok"
if [ -s "$TMP/ok" ]; then sed 's/^/  /' "$TMP/ok"; else echo "  (ninguna)"; fi
echo

echo "--- NO SE VEN: apps de movil, sin icono de televisor ---"
comm -23 "$TMP/mine" "$TMP/tv" > "$TMP/notv"
if [ -s "$TMP/notv" ]; then
  while IFS= read -r p; do
    if grep -qx "$p" "$TMP/phone"; then
      echo "  $p   (tiene icono de movil: FLauncher puede mostrarla si se lo pides)"
    else
      echo "  $p   (SIN icono de ningun tipo: no se puede abrir desde un lanzador)"
    fi
  done < "$TMP/notv"
  echo
  c_yel "Estas son la causa. En FLauncher: ajustes (rueda dentada) y busca la"
  c_yel "opcion de mostrar aplicaciones que no son de TV / 'non-TV apps'."
  echo
  echo "Para abrir una de estas ahora mismo, sin tocar FLauncher:"
  echo "  adb -s $TV shell monkey -p <PAQUETE> -c android.intent.category.LAUNCHER 1"
else
  c_grn "  (ninguna: todas tus apps tienen icono de televisor)"
  echo
  echo "Entonces no es el tipo de app. Es que FLauncher no la ha puesto en"
  echo "ninguna categoria: entra en sus ajustes y añadela a mano."
fi

echo
echo "=== Comprobacion: nada de lo que desactivamos afecta a esto ==="
for p in com.android.vending com.google.android.gms com.android.statementservice; do
  S="$(ash pm list packages -d | tr -d '\r' | grep -c "^package:${p}$")"
  [ "$S" = "0" ] && c_grn "  activo        $p" || c_red "  DESACTIVADO   $p  <-- revisar"
done
