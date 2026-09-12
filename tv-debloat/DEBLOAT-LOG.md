# DEBLOAT-LOG — Philips TPM191E (192.168.178.86)

Registro de qué se hizo, por qué, y cómo deshacerlo. **Regla 1: nada se
desinstala.** Todo es `pm disable-user --user 0`, reversible con `pm enable`.

---

## Estado actual

**Nada ejecutado todavía contra la tele.** La sesión de Claude que preparó
este toolkit corría en un contenedor en la nube, sin ruta de red hacia
192.168.178.86 (puerto 5555 inalcanzable, sin interfaz en la LAN doméstica).
Los comandos los lanzas tú; los scripts llevan las salvaguardas dentro.

---

## Corrección importante respecto al brief original

El brief traía una lista de intocables de un televisor **TCL**
(`com.tcl.suspension`, `com.tcl.tv`, `com.tcl.tvinput`, `com.tcl.autopair`,
`com.tcl.tcl_bt_rcu_service`). Esta tele es un **Philips**, fabricada por
TP Vision: **ninguno de esos paquetes existe aquí**. Los equivalentes viven
en `org.droidtv.*`.

Seguir la lista TCL al pie de la letra habría dejado la protección apuntando
a paquetes inexistentes mientras los que controlan de verdad las entradas
HDMI quedaban sin cubrir — justo el escenario «no puedo pasar a HDMI».

**Decisión:** en vez de adivinar nombres Philips de memoria,
`NEVER-DISABLE.txt` protege **los namespaces completos** `org.droidtv.*`,
`com.philips.*`, `com.tpv*`, `com.mediatek.*`. Ahí dentro están las entradas
HDMI, el menú Fuentes, el tuner, el Ambilight y el manejo del mando. Un
paquete sale de esa protección solo tras revisarlo sobre la lista real de
la tele.

## Otras correcciones frente al brief

| Punto del brief | Problema | Qué se hizo |
|---|---|---|
| `pm trim-caches` (paso e) | Exige un argumento de tamaño; tal cual falla con `Expected parameter` y no vacía nada | `04-tweaks.sh` usa `pm trim-caches 999G` |
| `com.android.shell` | No estaba en la lista de intocables, y **es ADB**: desactivarlo corta el acceso y deja el undo imposible salvo reset de fábrica | Añadido a `NEVER-DISABLE.txt` |
| WebView | No estaba protegido; sin él muchas apps se quedan en blanco | `com.android.webview` / `com.google.android.webview` protegidos |
| Orden del cambio de lanzador | Correcto en el brief, pero frágil si se hace a mano | `06-switch-launcher.sh` *verifica* que FLauncher es el home antes de desactivar el de Google; si no lo es, no toca nada |

---

## Fallo encontrado y corregido en el propio toolkit

Durante las pruebas con un `adb` simulado, la red de seguridad bloqueaba
**todos** los paquetes, incluido el salvapantallas que sí es basura segura.

Causa: `grep -f` interpreta una **línea vacía** del fichero de patrones como
un patrón que encaja con cualquier cosa (y un `#comentario` como patrón
literal). `NEVER-DISABLE.txt` tiene ambos por legibilidad.

Corregido con `never_file()` en `lib-common.sh`, que filtra comentarios y
líneas en blanco antes de pasar el fichero a `grep`. Sin ese arreglo la
clasificación en tres grupos también habría metido todo en «intocables».

---

## Hallazgos al revisar la lista real de la tele

La tele resultó ser un **Android TV clásico**, no Google TV. Tres cosas que
solo se vieron con la lista delante:

1. **El lanzador es `com.google.android.tvlauncher`**, no
   `com.google.android.apps.tv.launcherx`. Solo el segundo estaba protegido,
   así que la pantalla de inicio estaba cayendo en «sin clasificar», sin
   cubrir. Ambos protegidos ahora, y `06-switch-launcher.sh` detecta cuál
   existe en vez de darlo por supuesto.
2. **La clasificación automática metía Netflix y Prime Video en «basura
   segura».** El patrón barría las apps de streaming, pero el criterio del
   brief era «streaming que *no uso*», y eso solo lo sabe el usuario. Movidas
   al grupo 2 junto con `com.google.android.apps.mediashell` (el receptor de
   Chromecast, que no es basura: es la función «enviar a la tele»).
3. **Los RRO (`android.auto_generated_rro_*`, `com.android.tv.overlay.*`,
   `com.google.android.overlay.*`, `*.tpvcustom`) estaban sin proteger.** No
   son apps: llevan la personalización del fabricante (red, wifi, ajustes).
   Desactivarlos cambia la configuración del sistema de forma impredecible.
   Protegidos, junto con los módulos mainline (`ext.services`, `ext.shared`,
   `modulemetadata`), `com.android.inputdevices` (teclados físicos) y
   `com.android.vpndialogs` (este usuario tiene NordVPN).

La protección por namespaces sí funcionó como se esperaba: ni un `org.droidtv.*`
ni un `com.mediatek.*` apareció en «sin clasificar», todos quedaron en el
grupo 3.

## Paquetes desactivados

Ninguno todavía. `disabled.txt` se va rellenando solo, con una línea por
paquete y la tanda a la que pertenece.

### Tanda 1 — aplicada, las 7 pruebas del mando OK

| Paquete | Qué era |
|---|---|
| `com.google.android.backdrop` | Salvapantallas ambiental (fotos y sugerencias al estar parada) |
| `com.android.dreams.basic` | Salvapantallas básico |
| `com.google.android.tungsten.setupwraith` | Asistente de configuración inicial |
| `com.google.android.onetimeinitializer` | Tareas de primer arranque |
| `com.google.android.partnersetup` | Configuración/telemetría del fabricante con Google |
| `com.google.android.feedback` | Envío de informes de uso a Google |
| `com.google.android.syncadapters.calendar` | Sincronización de calendario |
| `com.android.printspooler` | Cola de impresión |
| `com.android.wallpaperbackup` | Copia del fondo de pantalla |

### Tanda 2 — decidida por el usuario

| Paquete | Qué era |
|---|---|
| `com.apple.atve.androidtv.appletv` | App de Apple TV |
| `com.google.android.play.games` | Juegos de Google |

### Lo que el usuario decidió CONSERVAR

Netflix, Prime Video, Atresplayer, RTVE, IPTV Smarters, Downloader, FitOn,
Chromecast (`mediashell`), navegador Vewd, Play-Fi y NordVPN. `com.easy.oad`
queda intacto: nadie sabe qué es, y «OAD» apunta a actualizaciones de
firmware.

---

## Deshacerlo todo

Un solo comando:

```bash
./05-undo-all.sh
```

Reactiva cada paquete de `disabled.txt`, devuelve las animaciones a `1.0`,
restaura la pantalla de inicio que había (guardada en `previous-home.txt`)
y reinicia.

Si solo se quiere deshacer **la última tanda** porque algo se rompió
(regla 7):

```bash
./revert-last-batch.sh
```
