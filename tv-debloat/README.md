# Limpieza por ADB — Philips TPM191E

Scripts para quitar anuncios y filas de recomendaciones, desactivar apps de
fábrica y acelerar la tele. **Nada se desinstala:** todo es
`pm disable-user --user 0`, reversible.

> **¿Primera vez y con un Mac?** Lee [`GUIA-MAC.md`](GUIA-MAC.md): los mismos
> pasos pero explicados desde cero, incluido cómo abrir la Terminal.

## Orden de ejecución

```bash
cd tv-debloat

./00-setup-adb.sh 192.168.178.86   # instala adb y conecta (mira la tele: te pedirá permiso)
./01-measure.sh antes              # guarda RAM y lista de paquetes
./02-triage.sh                     # reparte en 3 grupos -> batches/
                                   #   >>> PASAME batches/grupo0 y grupo1 ANTES DE SEGUIR <<<
./03-disable-batch.sh batches/tanda-01.txt   # máx 10, y PARA para que pruebes
# ... una tanda cada vez, probando la tele entre medias ...
./04-tweaks.sh                     # animaciones al 50% + vaciar cachés
adb reboot
./01-measure.sh despues
./99-report.sh                     # tabla antes/después
```

Cambio de pantalla de inicio (aparte, cuando lo anterior vaya bien):

```bash
# 1. Instala FLauncher TÚ desde la Play Store de la tele
./06-switch-launcher.sh            # comprueba, lo pone como home, y SOLO ENTONCES
                                   # desactiva el lanzador de Google
adb reboot                         # comprueba que arranca en FLauncher
```

## Botones de pánico

| Situación | Comando |
|---|---|
| Algo se rompió tras una tanda | `./revert-last-batch.sh` |
| Quiero dejarlo todo como estaba | `./05-undo-all.sh` |
| Pantalla negra al arrancar | `adb shell pm enable com.google.android.apps.tv.launcherx && adb reboot` |

## Por qué no puedes saltarte `02-triage.sh`

Esta tele es Philips (TP Vision), no TCL. Los paquetes que controlan las
entradas HDMI y el menú Fuentes se llaman `org.droidtv.*`, y su nombre exacto
cambia entre chasis. `NEVER-DISABLE.txt` protege el namespace entero por
defecto; la clasificación existe para sacar de ahí solo lo que hayamos
revisado sobre la lista real de la tele.

El grupo 0 («sin clasificar») es el que importa: son los paquetes que el
script no reconoce. **No se desactiva nada de ahí a ciegas.**

## Nada de root

No hay ningún paso que toque root, bootloader ni ROM. `pm disable-user` no
lo necesita, y el certificado Widevine L1 se queda donde está (Netflix sigue
en HD). `NEVER-DISABLE.txt` protege además los paquetes DRM.

## Ficheros

| Fichero | Para qué |
|---|---|
| `NEVER-DISABLE.txt` | Patrones protegidos. La red de seguridad. |
| `disabled.txt` | Registro automático de lo desactivado (regla 6). |
| `DEBLOAT-LOG.md` | Qué se hizo, por qué, y cómo deshacerlo. |
| `previous-home.txt` | Lanzador anterior, para restaurarlo. |
| `measurements/` | Medidas `antes/` y `despues/`. |
| `GUIA-MAC.md` | Guía paso a paso para Mac sin experiencia en terminal. |
| `batches/` | Grupos y tandas. |
