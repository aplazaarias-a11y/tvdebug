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

## Instalo una app nueva y no sale en la pantalla de inicio

Normal, y no está roto nada. FLauncher no añade las apps nuevas a la cuadrícula
por su cuenta como hacía el lanzador de Google: hay que decirle dónde va cada
una.

**La rutina, cada vez que instales algo:**
FLauncher → rueda dentada (ajustes) → categorías → añadir aplicaciones.

Si la app sigue sin aparecer después de eso, puede ser que sea una app de móvil
y no de televisor. Android distingue las dos cosas:

- `LEANBACK_LAUNCHER` → app de televisor, los lanzadores de TV la muestran
- solo `LAUNCHER` → app de móvil, los lanzadores de TV la **ocultan** por
  defecto, aunque esté perfectamente instalada

Para saber en qué caso estás:

```bash
./08-diagnose-apps.sh
```

Reparte tus apps en los tres grupos y te dice qué tocar. Si es app de móvil,
la opción está en los ajustes de FLauncher, en la línea de mostrar aplicaciones
que no son de TV.

Para abrir una app que no veas, sin pasar por el lanzador:

```bash
adb -s 192.168.178.86:5555 shell monkey -p NOMBRE.DEL.PAQUETE -c android.intent.category.LAUNCHER 1
```

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
