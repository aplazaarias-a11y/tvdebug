#!/usr/bin/env bash
# Regla 4: tandas de 10 como maximo, y PARAR para que pruebes.
# Regla 1: solo 'pm disable-user --user 0'. NUNCA 'pm uninstall'.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"
need_device

FILE="${1:-}"
[ -z "$FILE" ]  && die "uso: $0 <fichero-con-paquetes>   (p.ej. batches/tanda-01.txt)"
[ -f "$FILE" ]  || die "no existe: $FILE"
MAX=10

PKGS=(); while IFS= read -r l; do
  l="$(echo "$l" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "$l" ] && PKGS+=("$l")
done < "$FILE"

[ "${#PKGS[@]}" -eq 0 ] && die "$FILE no tiene ningun paquete"
if [ "${#PKGS[@]}" -gt "$MAX" ]; then
  die "$FILE trae ${#PKGS[@]} paquetes y el maximo por tanda es $MAX (regla 4). Partelo."
fi

# ---------- RED DE SEGURIDAD: se comprueba TODO antes de tocar nada ----------
echo "=== Comprobando la lista de intocables ==="
BLOCKED=0
for p in "${PKGS[@]}"; do
  if is_protected "$p"; then
    c_red "  BLOQUEADO  $p  (encaja con NEVER-DISABLE.txt)"
    BLOCKED=1
  elif ! grep -qx "$p" "$DIR/measurements/antes/packages-all.txt" 2>/dev/null; then
    c_yel "  AVISO      $p  no aparece en la lista de tu tele. ¿Nombre mal escrito?"
    BLOCKED=1
  else
    echo "  ok         $p"
  fi
done
[ "$BLOCKED" -eq 1 ] && die "Abortado sin tocar nada. Arregla la lista y repite."

echo
echo "=== Desactivando ${#PKGS[@]} paquetes ==="
LOG="$DIR/disabled.txt"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TANDA="$(basename "$FILE")"
[ -f "$LOG" ] || echo "# paquete  |  tanda  |  fecha   -- deshacer: adb shell pm enable <paquete>" > "$LOG"

OKS=0; FAILS=0
for p in "${PKGS[@]}"; do
  OUT="$(ash pm disable-user --user 0 "$p" 2>&1)"
  if grep -qi 'new state: disabled' <<<"$OUT"; then
    c_grn "  desactivado  $p"
    printf '%-55s | %-16s | %s\n' "$p" "$TANDA" "$STAMP" >> "$LOG"
    OKS=$((OKS+1))
  else
    c_red "  FALLO        $p  ->  $OUT"
    FAILS=$((FAILS+1))
  fi
done

echo
echo "Hechos: $OKS   Fallidos: $FAILS"
echo "Apuntados en disabled.txt"
echo
c_yel "============ PARA AQUI Y PRUEBA LA TELE (regla 4) ============"
cat <<'CHECKS'
Con el mando, uno por uno:
  [ ] El boton FUENTES / ENTRADAS abre el menu
  [ ] Puedes cambiar a HDMI 1 / 2 / 3 y se ve imagen
  [ ] Netflix abre y reproduce
  [ ] YouTube abre y reproduce
  [ ] Hay sonido
  [ ] El teclado en pantalla sale al buscar algo
  [ ] El mando responde (flechas, volumen, atras, home)

Si TODO va bien -> dimelo y preparo la siguiente tanda.
Si algo se ha roto -> ejecuta AHORA MISMO:
      ./revert-last-batch.sh
y luego afinamos paquete a paquete.
CHECKS
