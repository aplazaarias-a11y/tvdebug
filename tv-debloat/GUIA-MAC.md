# Guía paso a paso — Mac, sin experiencia previa

Tiempo total: unos 40 minutos, la mayoría esperando descargas.
Ten el mando de la tele a mano y la tele encendida.

Cosas que conviene saber antes de empezar:

- **Copiar y pegar**: `⌘C` para copiar, `⌘V` para pegar. Funciona en la Terminal.
- **Cada comando acaba pulsando `Intro`**. Un comando no hace nada hasta que
  pulsas Intro.
- **Cuando te pida la contraseña del Mac, NO se ve nada al teclear.** Ni
  puntitos ni asteriscos. Es normal, no está roto. Teclea y pulsa Intro.
- Si algo sale mal, no pasa nada: en esta guía no se toca la tele hasta la
  PARTE 3.

---

## PARTE 1 — Preparar el Mac (solo la primera vez)

### Paso 1. Abrir la Terminal

1. Pulsa `⌘` (command) + `barra espaciadora`. Sale un buscador en el centro.
2. Escribe: `terminal`
3. Pulsa `Intro`.

Se abre una ventana con fondo blanco o negro y un texto que acaba en `$` o
`%`. Ese es el sitio donde vas a escribir todo. Déjala abierta.

### Paso 2. Instalar Homebrew

Homebrew es un instalador de programas para Mac. Lo necesitamos porque trae
`adb` (el programa que habla con la tele) ya listo para funcionar.

Copia esta línea entera, pégala en la Terminal y pulsa Intro:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Qué va a pasar:

- Te enseña una lista de lo que va a instalar y dice
  `Press RETURN to continue`. Pulsa `Intro`.
- Te pide tu contraseña del Mac. **No verás nada al teclearla.** Teclea y
  pulsa Intro.
- Tarda entre 5 y 15 minutos. Verás mucho texto pasando. Es normal.
- Al final, si te muestra dos líneas que empiezan por `echo` y te dice
  `Run these commands in your terminal`, **cópialas y ejecútalas**. Son para
  que el Mac encuentre Homebrew.

### Paso 3. Instalar adb

```
brew install android-platform-tools
```

Tarda un par de minutos.

### Paso 4. Comprobar que ha funcionado

```
adb version
```

Si responde algo como `Android Debug Bridge version 1.0.41`, vas bien.

Si dice `command not found: adb`, cierra la Terminal entera, abre una nueva
(Paso 1) y repite el Paso 4.

---

## PARTE 2 — Bajar los scripts

Un comando por línea, pulsando Intro después de cada uno:

```
cd ~/Desktop
```

```
git clone https://github.com/aplazaarias-a11y/tvdebug.git
```

No te pedirá contraseña: el repositorio es público.

```
cd ~/Desktop/tvdebug/tv-debloat
```

```
chmod +x *.sh
```

Qué hace cada uno: te pone en el Escritorio, descarga los scripts ahí, entra
en la carpeta, y da permiso de ejecución a los scripts.

Ahora tienes una carpeta `tvdebug` en tu Escritorio. Puedes abrirla con el
Finder y mirarla si quieres.

> **Importante:** a partir de aquí, **todos** los comandos hay que lanzarlos
> desde esta carpeta. Si cierras la Terminal y vuelves luego, lo primero que
> tienes que escribir es:
> ```
> cd ~/Desktop/tvdebug/tv-debloat
> ```

---

## PARTE 3 — Conectar con la tele

Aquí empezamos a tocar la tele, pero solo para *leer*. Nada se desactiva.

```
./00-setup-adb.sh 192.168.178.86
```

(Esa `./` del principio es obligatoria. Significa "el script de esta carpeta".)

A partir de aquí **lee lo que te dice el script**, porque hay tres finales
posibles:

### Final A — Conectado

Dice `Conectado a 192.168.178.86:5555` y te muestra el modelo de la tele.
Perfecto, salta a la PARTE 4.

### Final B — Te pide permiso en la tele

Dice `La tele pide autorizacion`.

**Mira la pantalla de la tele ahora.** Ha salido una ventana que pregunta
algo como *"¿Permitir la depuración USB desde este ordenador?"*.

1. Con el mando, marca la casilla **"Permitir siempre desde este ordenador"**.
2. Elige **Permitir** / **Aceptar**.
3. Vuelve a la Terminal y repite el comando del Paso de la PARTE 3.

### Final C — Hace falta emparejar con código

Dice `No ha conectado al puerto 5555` y habla de emparejamiento. Tu Philips
es Android 11 o superior, así que es el caso más probable.

En la tele, con el mando:

1. **Ajustes** (la tecla del engranaje, o Inicio → icono de engranaje)
2. Busca **Preferencias del dispositivo** → **Opciones para desarrolladores**
3. Dentro, busca **Depuración inalámbrica** y ábrela
4. Elige **Vincular dispositivo con código de emparejamiento**

La tele te muestra ahora en pantalla:

- un **código de 6 cifras**
- una **dirección con un puerto**, tipo `192.168.178.86:37251`
  — ojo, **ese puerto NO es el 5555**, es otro número

En la Terminal escribe esto, cambiando `37251` por el puerto que veas
**en tu tele**:

```
adb pair 192.168.178.86:37251
```

Te pedirá `Enter pairing code:`. Teclea las 6 cifras y pulsa Intro.
Debe responder `Successfully paired`.

> Los nombres de los menús cambian un poco según la versión de software de
> Philips. Si no encuentras "Depuración inalámbrica", dime qué opciones ves
> dentro de "Opciones para desarrolladores" y te guío.

Luego:

```
./00-setup-adb.sh 192.168.178.86
```

y deberías llegar al Final A.

---

## PARTE 4 — Medir y clasificar

Esto tampoco cambia nada en la tele. Solo mira y apunta.

```
./01-measure.sh antes
```

Guarda cuánta memoria está usando la tele y la lista completa de programas
que tiene instalados. Es la foto del "antes" para poder comparar al final.

```
./02-triage.sh
```

Reparte los programas en los tres grupos: basura segura, depende de ti, e
intocables.

---

## PARTE 5 — Mándame el resultado

Ahora necesito ver los nombres reales de los programas de **tu** tele, porque
los de Philips cambian según el modelo y no me los quiero inventar.

```
cat batches/grupo0-sin-clasificar.txt
```

```
cat batches/grupo1-basura-segura.txt
```

Cada comando escupe una lista en la Terminal. **Selecciónalas con el ratón,
cópialas con `⌘C` y pégamelas en el chat.**

Con eso preparo la primera tanda de 10 y seguimos. **No ejecutes
`03-disable-batch.sh` por tu cuenta todavía** — es el primer script que
desactiva cosas de verdad, y quiero ver tu lista antes.

---

## Si algo va mal en cualquier momento

Nada de lo que hay en esta guía (PARTES 1 a 5) desactiva nada en la tele, así
que no puedes romperla siguiendo estos pasos.

Más adelante, cuando ya estemos desactivando cosas:

| Problema | Comando |
|---|---|
| Algo dejó de funcionar tras una tanda | `./revert-last-batch.sh` |
| Quiero dejar la tele como estaba | `./05-undo-all.sh` |

Y si te pierdes, pégame en el chat el texto que te haya salido en la Terminal.
Con eso suelo ver qué pasa.
