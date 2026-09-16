# Módulo 02 — Filesystem de Linux

**Fase I — Linux Fundamentals**

---

## Objetivos del módulo

- Entender la estructura de directorios de Linux (FHS) y qué va en cada carpeta.
- Entender "todo es un archivo" — la filosofía central de Unix/Linux.
- Diferenciar rutas absolutas y relativas.
- Saber inspeccionar y manipular archivos y permisos básicos de forma segura.

---

## 1. CONCEPTO: "todo es un archivo"

En Linux, casi todo se representa como un archivo: documentos, carpetas, dispositivos de hardware (un disco, un puerto USB), e incluso procesos en ejecución (a través de `/proc`). Esto no es una metáfora — es una decisión de diseño real de Unix que simplifica enormemente cómo interactúan los programas con el sistema: un mismo conjunto de herramientas (leer, escribir, abrir, cerrar) sirve para casi cualquier cosa, sin necesitar una API distinta para cada tipo de recurso.

No hay un único disco "C:" como en Windows. Hay **un solo árbol de directorios**, empezando en `/` (la raíz), y todo —discos externos, particiones, dispositivos— se "engancha" (se monta) en algún punto de ese árbol.

---

## 2. POR QUÉ EXISTE: el FHS (Filesystem Hierarchy Standard)

### El problema que resuelve

Si cada distribución de Linux pusiera los archivos de configuración, binarios y logs donde quisiera, ningún programa ni administrador podría predecir dónde encontrar nada. El **FHS** es un estándar que define **qué tipo de contenido va en qué carpeta**, para que cualquier sistema Linux (Arch, Debian, Fedora) tenga una estructura predecible.

### Carpetas principales que vas a usar constantemente

| Carpeta | Contenido |
|---|---|
| `/` | Raíz del sistema, todo cuelga de acá |
| `/home` | Carpetas personales de cada usuario (`/home/fabian`) |
| `/etc` | Archivos de **configuración** del sistema y de programas |
| `/bin`, `/usr/bin` | Binarios (programas ejecutables) del sistema |
| `/var` | Datos **variables**: logs (`/var/log`), colas, cachés |
| `/tmp` | Archivos temporales, se borran al reiniciar |
| `/root` | Home del usuario administrador (`root`), no confundir con `/` |
| `/dev` | Archivos que representan dispositivos de hardware (discos, terminales) |
| `/proc` | Información en tiempo real del kernel y los procesos (no son archivos reales en disco) |
| `/boot` | Archivos necesarios para el arranque (kernel, initramfs) — clave en el Módulo 10 |
| `/mnt`, `/media` | Puntos de montaje temporales para discos externos o particiones |

**Por qué te importa memorizar esto (con el tiempo, no ahora):** cuando en el Módulo 15 busques por qué falló un servicio, vas a saber instintivamente que los logs están en `/var/log`. Cuando en el Módulo 06 instales Arch, vas a saber por qué `/boot` necesita ser una partición separada. Esta tabla es el mapa que sostiene todo el resto del curso.

---

## 3. CÓMO FUNCIONA: rutas absolutas vs. relativas

- **Ruta absoluta:** empieza desde la raíz `/`. Siempre apunta al mismo lugar, sin importar dónde estés parado.
  ```bash
  cd /home/fabian/lab01
  ```
- **Ruta relativa:** se interpreta según el directorio en el que estás parado ahora (`pwd`).
  ```bash
  cd lab01        # solo funciona si ya estás en /home/fabian
  cd ../otra      # ".." significa "un nivel arriba"
  cd ./script.sh  # "." significa "el directorio actual"
  ```

**Regla práctica:** en scripts y automatización (Módulo 17 en adelante) siempre vas a preferir rutas absolutas — son inequívocas. En uso interactivo del día a día, las relativas son más rápidas de escribir.

---

## 4. HERRAMIENTA: inspeccionar y manipular archivos

```bash
file archivo.txt        # ¿qué tipo de archivo es realmente? (no confiar solo en la extensión)
cat archivo.txt          # muestra el contenido completo de un archivo de texto
less archivo.txt         # muestra el contenido paginado (mejor para archivos largos); salís con "q"
head -n 5 archivo.txt    # las primeras 5 líneas
tail -n 5 archivo.txt    # las últimas 5 líneas
tail -f /var/log/algun.log  # sigue el archivo en vivo, a medida que crece (muy usado en troubleshooting)
du -sh carpeta/          # cuánto espacio en disco ocupa una carpeta
df -h                    # espacio libre/usado en cada partición montada
find /etc -name "*.conf" # busca archivos por nombre dentro de un árbol de directorios
```

### Permisos básicos (adelanto — el detalle completo es el Módulo 04)

```bash
ls -l archivo.txt
```

Vas a ver algo como `-rw-r--r-- 1 fabian fabian 120 sep 10 19:00 archivo.txt`. Esos primeros 10 caracteres son el tipo de archivo y los permisos (lectura/escritura/ejecución para dueño/grupo/otros). Lo vamos a desarmar por completo en el Módulo 04 — por ahora solo reconocelo cuando lo veas.

---

## 5. EJEMPLO

```bash
cd /
ls -la                       # mirá la raíz del sistema completo
file /bin/bash                 # ¿qué tipo de archivo es bash?
du -sh /var/log                # ¿cuánto pesan los logs acumulados?
df -h                           # ¿cuánto espacio libre tenés en tu disco sda?
find /etc -name "*.conf" | head -n 10   # los primeros 10 archivos .conf que encuentre
```

---

## 6. PRÁCTICA

Ejecutá y contame el resultado:

1. `ls -la /` — ¿qué carpetas ves en la raíz?
2. `df -h` — ¿cuánto espacio total y libre tiene tu disco?
3. `du -sh /var/log` — ¿cuánto pesan tus logs actuales?
4. Desde tu home, probá una ruta relativa: `cd /` y después `cd home/fabian` (sin la barra inicial) — ¿funcionó? ¿Por qué sí o no?
5. `find /etc -name "*.conf"` — ¿cuántos resultados aparecen aproximadamente?

---

## 7. ERROR INTENCIONAL

```bash
cd /etc/algo-que-no-existe
cat /etc/passwd/nada
```

El segundo es más interesante: `/etc/passwd` es un **archivo**, no una carpeta, así que intentar entrar "dentro" de él como si fuera un directorio genera un error distinto al de "no existe".

---

## 8. DIAGNÓSTICO Y SOLUCIÓN

- `cd /etc/algo-que-no-existe` → `No such file or directory` (la ruta no existe, igual que en el Módulo 01).
- `cat /etc/passwd/nada` → algo como `Not a directory` — el sistema te avisa que `/etc/passwd` **existe pero es un archivo**, no una carpeta, así que no podés tratarlo como si tuviera contenido "adentro". La solución es simplemente `cat /etc/passwd` sin agregarle nada después.

Esto refuerza algo clave: en Linux, **el mensaje de error casi siempre te dice exactamente qué tipo de problema es** (no existe vs. no es del tipo esperado) — aprender a leerlo con atención te ahorra minutos de diagnóstico a ciegas.

---

## Checklist de cierre del módulo

- [ ] Entiendo la filosofía "todo es un archivo".
- [ ] Conozco el propósito de `/home`, `/etc`, `/var`, `/bin`, `/tmp`, `/boot`, `/proc`, `/dev`.
- [ ] Sé diferenciar rutas absolutas de relativas.
- [ ] Puedo usar `cat`, `less`, `head`, `tail`, `du`, `df`, `find`.
- [ ] Completé la práctica en mi VM.

---

**Próximo módulo:** 03 — Texto y procesamiento (pipes, redirecciones).
