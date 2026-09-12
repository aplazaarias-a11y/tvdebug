#!/usr/bin/env bash
# Funciones compartidas. No se ejecuta sola.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADB="${ADB:-adb}"
TV="${TV:-192.168.178.86:5555}"

c_red()  { printf '\033[31m%s\033[0m\n' "$*"; }
c_grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_yel()  { printf '\033[33m%s\033[0m\n' "$*"; }
die()    { c_red "ERROR: $*"; exit 1; }

# adb shell limpiando los \r que mete Windows/adb
ash() { "$ADB" -s "$TV" shell "$@" | tr -d '\r'; }

need_device() {
  command -v "$ADB" >/dev/null 2>&1 || die "adb no esta instalado. Ejecuta ./00-setup-adb.sh"
  if ! "$ADB" devices | tr -d '\r' | grep -q "^${TV}[[:space:]]*device$"; then
    c_red "La tele $TV no aparece como 'device'."
    "$ADB" devices
    echo
    echo "Prueba:  adb connect $TV"
    echo "Si la tele pide un codigo de emparejamiento, usa primero:  adb pair <IP>:<PUERTO>"
    exit 1
  fi
}

# NEVER-DISABLE.txt se lee con 'grep -f', y ahi una linea VACIA es un patron
# que encaja con CUALQUIER cosa (y un comentario '#...' es un patron literal).
# Hay que limpiarlo antes de usarlo o la proteccion bloquea todo.
NEVER_CLEAN=""
never_file() {
  if [ -z "$NEVER_CLEAN" ]; then
    NEVER_CLEAN="$(mktemp)"
    sed 's/[[:space:]]*$//' "$DIR/NEVER-DISABLE.txt" \
      | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' > "$NEVER_CLEAN"
  fi
  echo "$NEVER_CLEAN"
}
is_protected() { grep -qEf "$(never_file)" <<<"$1"; }
