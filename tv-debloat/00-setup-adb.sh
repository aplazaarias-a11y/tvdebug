#!/usr/bin/env bash
# Paso (a): instala adb si falta y conecta con la tele.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib-common.sh"

IP="${1:-192.168.178.86}"

echo "=== 1. Detectando tu sistema operativo ==="
OS="desconocido"
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
esac
echo "Detectado: $OS"

if command -v adb >/dev/null 2>&1; then
  c_grn "adb ya esta instalado: $(adb version | head -1)"
else
  c_yel "adb no esta. Instalando..."
  case "$OS" in
    macos)
      command -v brew >/dev/null 2>&1 || die "Falta Homebrew. Instalalo desde https://brew.sh y repite."
      brew install android-platform-tools || die "Fallo brew install"
      ;;
    linux)
      if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y adb || die "Fallo apt install adb"
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y android-tools
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm android-tools
      else
        die "No reconozco tu gestor de paquetes. Instala 'adb' a mano."
      fi
      ;;
    windows)
      echo "En Windows hazlo a mano (son 2 minutos):"
      echo "  1. Descarga https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
      echo "  2. Descomprime en C:\\platform-tools"
      echo "  3. Anade C:\\platform-tools al PATH:"
      echo "     Inicio > 'variables de entorno' > Path > Editar > Nuevo > C:\\platform-tools"
      echo "  4. Abre una terminal NUEVA y repite este script."
      exit 1
      ;;
    *) die "SO no reconocido. Instala adb a mano." ;;
  esac
fi

echo
echo "=== 2. Conectando con la tele ($IP) ==="
adb start-server >/dev/null 2>&1
adb connect "${IP}:5555" || true
sleep 2

if adb devices | tr -d '\r' | grep -q "^${IP}:5555[[:space:]]*device$"; then
  c_grn "Conectado a ${IP}:5555"
elif adb devices | tr -d '\r' | grep -q "unauthorized"; then
  c_yel "La tele pide autorizacion."
  echo "--> MIRA LA PANTALLA DE LA TELE AHORA."
  echo "    Sale '¿Permitir la depuracion USB desde este ordenador?'."
  echo "    Marca 'Permitir siempre' y acepta. Luego repite este script."
  exit 2
else
  c_yel "No ha conectado al puerto 5555."
  echo
  echo "Tu Philips es Android 11+, asi que probablemente necesita EMPAREJAMIENTO:"
  echo "  1. En la tele: Ajustes > Sistema > Opciones de desarrollador"
  echo "                 > Depuracion inalambrica > Vincular dispositivo con codigo"
  echo "  2. La tele muestra un codigo de 6 digitos y un puerto (NO es el 5555)."
  echo "  3. Aqui ejecuta:   adb pair ${IP}:<ESE_PUERTO>"
  echo "     y teclea el codigo."
  echo "  4. Luego:          adb connect ${IP}:5555"
  echo "  5. Repite este script."
  exit 3
fi

echo
echo "=== 3. Identificando la tele ==="
echo "Modelo:       $(adb -s ${IP}:5555 shell getprop ro.product.model | tr -d '\r')"
echo "Fabricante:   $(adb -s ${IP}:5555 shell getprop ro.product.manufacturer | tr -d '\r')"
echo "Chasis:       $(adb -s ${IP}:5555 shell getprop ro.build.product | tr -d '\r')"
echo "Android:      $(adb -s ${IP}:5555 shell getprop ro.build.version.release | tr -d '\r')"
echo
c_grn "Listo. Siguiente paso:  ./01-measure.sh antes"
