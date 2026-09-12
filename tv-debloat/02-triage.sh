#!/usr/bin/env bash
# Paso (c): reparte los paquetes en los tres grupos y saca una tabla.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"

SRC="$DIR/measurements/antes/packages-enabled.txt"
[ -f "$SRC" ] || die "Falta la medida inicial. Ejecuta primero ./01-measure.sh antes"

G1="$DIR/batches/grupo1-basura-segura.txt"
G2="$DIR/batches/grupo2-depende-de-mi.txt"
G3="$DIR/batches/grupo3-intocables.txt"
UNK="$DIR/batches/grupo0-sin-clasificar.txt"
: > "$G1"; : > "$G2"; : > "$G3"; : > "$UNK"

# --- Grupo 1: basura segura (demos, salvapantallas, asistentes, telemetria) --
P_G1='^com\.google\.android\.backdrop$|^com\.google\.android\.tungsten\.setupwraith$|^com\.google\.android\.tungsten\.overscan$|^com\.google\.android\.feedback$|^com\.google\.android\.printservice\.recommendation$|^com\.google\.android\.partnersetup$|^com\.google\.android\.onetimeinitializer$|^com\.google\.android\.syncadapters\.|^com\.android\.wallpaper|^com\.android\.dreams|daydream|screensaver|^com\.android\.bookmarkprovider$|^com\.android\.printspooler$|^com\.android\.easteregg$|^com\.google\.android\.music$|^com\.google\.android\.apps\.magazines$|^com\.google\.android\.apps\.books$|demo$|\.demo\.|retaildemo|oobe|analytics|telemetry|crashreport'

# --- Grupo 2: pregúntale al usuario si de verdad los usa --------------------
P_G2='^com\.netflix\.|^com\.amazon\.amazonvideo|^com\.disney\.|^com\.spotify\.|^com\.rakuten|^com\.pluto|^tv\.molotov|^tv\.twitch|^com\.hbo|^com\.plexapp|^com\.deezer|^com\.tidal|^com\.google\.android\.videos$|^com\.google\.android\.play\.games|^com\.google\.android\.apps\.mediashell$|^com\.antena3\.|^com\.rtve\.|^com\.apple\.atve|^com\.phorus\.playfi|^com\.vewd\.|^com\.nordvpn\.|^com\.esaba\.downloader$|^com\.nst\.|^com\.fiton\.|^com\.google\.android\.youtube|^com\.google\.android\.katniss$|^com\.google\.android\.apps\.tv\.dreamx$|^com\.google\.android\.tvrecommendations$|^com\.google\.android\.gms\.location\.history$|^com\.google\.android\.marvin\.talkback$|^com\.google\.android\.tts$|^com\.android\.chrome$|^com\.google\.android\.googlequicksearchbox$|^com\.google\.android\.apps\.photos|^com\.google\.android\.calendar|^com\.google\.android\.apps\.chromecast|^com\.google\.android\.apps\.mediarouter|cast|assistant|^com\.android\.bips$|^com\.android\.cellbroadcast|^com\.android\.emergency$|^com\.android\.traceur$|^com\.google\.android\.apps\.youtube\.music'

while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  if is_protected "$pkg"; then
    echo "$pkg" >> "$G3"
  elif grep -qE "$P_G1" <<<"$pkg"; then
    echo "$pkg" >> "$G1"
  elif grep -qE "$P_G2" <<<"$pkg"; then
    echo "$pkg" >> "$G2"
  else
    echo "$pkg" >> "$UNK"
  fi
done < "$SRC"

printf '%-44s %s\n' "GRUPO" "Nº"
printf '%-44s %s\n' "------------------------------------------" "---"
printf '%-44s %s\n' "1 - basura segura (se desactiva)"     "$(wc -l < "$G1")"
printf '%-44s %s\n' "2 - depende de ti (te pregunto)"      "$(wc -l < "$G2")"
printf '%-44s %s\n' "3 - INTOCABLES (protegidos por regex)" "$(wc -l < "$G3")"
printf '%-44s %s\n' "0 - sin clasificar (revisar juntos)"   "$(wc -l < "$UNK")"
echo
echo "Ficheros en batches/. El grupo 0 es el importante: son los paquetes que"
echo "no reconozco. NO se desactiva nada de ahi sin revisarlo."
echo
echo "Pasame el contenido de batches/grupo0-sin-clasificar.txt y"
echo "batches/grupo1-basura-segura.txt y los repaso uno a uno."
