# Módulo 01 — Terminal y shell

**Fase I — Linux Fundamentals**

---

## Objetivos del módulo

Al terminar este módulo vas a poder explicar y aplicar:

- Qué es realmente una terminal y qué es un shell (y por qué no son lo mismo).
- Cómo se estructura un comando: programa, opciones (flags) y argumentos.
- Cómo moverte por el sistema de archivos desde la línea de comandos.
- Cómo pedir ayuda al sistema en vez de memorizar comandos (`man`, `--help`).
- Variables de entorno básicas y por qué existen.
- El concepto de "todo es un proceso ejecutándose sobre un shell", que vas a necesitar en el Módulo 05.

---

## 1. CONCEPTO: terminal vs. shell

Estas dos palabras se usan como sinónimos coloquialmente, pero son cosas distintas y separarlas te va a evitar confusión más adelante (por ejemplo, cuando conectes por SSH sin ninguna "ventana" de por medio).

- **Terminal (o emulador de terminal):** es el programa que te da una ventana de texto donde escribís y ves resultados. Es solo la interfaz visual — captura tu teclado y muestra texto en pantalla.
- **Shell:** es el programa que **interpreta** lo que escribís, lo traduce en llamadas al sistema (syscalls) y te devuelve el resultado. Es el verdadero "cerebro" que entiende tus comandos. Arch Linux usa **bash** por defecto (aunque hay otros: zsh, fish).

```
┌─────────────────────────────┐
│   Terminal (la ventana)     │  ← solo muestra texto, no entiende comandos
├─────────────────────────────┤
│   Shell (bash)               │  ← interpreta lo que escribís
├─────────────────────────────┤
│   Kernel Linux                │  ← ejecuta lo que el shell le pide
└─────────────────────────────┘
```

**Por qué importa:** cuando más adelante uses SSH (Módulo 13) para conectarte a un servidor remoto sin interfaz gráfica, no hay "terminal" visual de por medio en el sentido tradicional — pero el shell sigue estando ahí, interpretando tus comandos igual. Entender esta separación te prepara para eso.

---

## 2. POR QUÉ EXISTE: la línea de comandos frente a la interfaz gráfica

### El problema que resuelve

Una interfaz gráfica (GUI) es cómoda para tareas simples y visuales, pero tiene límites serios para administración de sistemas:

- No es **componible**: no podés encadenar fácilmente el resultado de una acción como entrada de otra.
- No es **automatizable**: no podés "grabar" una secuencia de clics y repetirla en 500 servidores.
- No es **precisa**: describir "todos los archivos modificados en la última hora que pesen más de 10MB" con clics es casi imposible; con una línea de comandos es una sola instrucción.

La terminal (con un shell como bash) resuelve esto porque cada comando es:

1. **Preciso** — hace exactamente lo que le pediste, sin ambigüedad.
2. **Componible** — la salida de un comando puede ser la entrada de otro (esto lo vas a explotar a fondo en el Módulo 03 — pipes y redirecciones).
3. **Automatizable** — una secuencia de comandos se puede guardar en un archivo (script) y ejecutar miles de veces, en cualquier máquina, de forma idéntica.

Esta es la razón de fondo por la que todo administrador de sistemas, DevOps o ingeniero de seguridad vive en la terminal: no es una preferencia estética, es que **es la única forma práctica de operar sistemas a escala**.

---

## 3. CÓMO FUNCIONA: anatomía de un comando

Todo comando en el shell sigue esta estructura:

```
programa  [opciones/flags]  [argumentos]
```

Ejemplo:

```bash
ls -la /home
```

- `ls` → el **programa** a ejecutar (list — listar).
- `-la` → **opciones/flags** que modifican el comportamiento (`-l` = formato largo, `-a` = incluir archivos ocultos). Se pueden combinar así porque son flags de una sola letra.
- `/home` → el **argumento**: sobre qué directorio actuar.

### Cómo el shell encuentra el programa: la variable `PATH`

Cuando escribís `ls`, el shell no sabe mágicamente dónde está ese programa. Busca en una lista de carpetas definida en la variable de entorno `PATH`. Podés verla así:

```bash
echo $PATH
```

Vas a ver algo como `/usr/local/sbin:/usr/local/bin:/usr/bin`. El shell revisa esas carpetas **en orden** hasta encontrar un archivo ejecutable llamado `ls`. Esto explica por qué a veces instalás un programa y el shell dice "comando no encontrado": el ejecutable no está en ninguna carpeta listada en `PATH`.

---

## 4. HERRAMIENTA: comandos esenciales de navegación

No hace falta memorizar todo de una vez — vas a interiorizarlos por uso repetido. Estos son los que vas a usar en cada sesión de trabajo:

| Comando | Qué hace |
|---|---|
| `pwd` | Muestra el directorio (carpeta) en el que estás parado ahora (*print working directory*) |
| `ls` | Lista el contenido de un directorio |
| `cd <ruta>` | Cambia de directorio (*change directory*) |
| `cd ..` | Sube un nivel (al directorio padre) |
| `cd ~` o `cd` (sin argumentos) | Va a tu directorio de usuario (home) |
| `mkdir <nombre>` | Crea un directorio nuevo |
| `touch <archivo>` | Crea un archivo vacío (o actualiza su fecha si ya existe) |
| `cp <origen> <destino>` | Copia un archivo o directorio |
| `mv <origen> <destino>` | Mueve o renombra un archivo/directorio |
| `rm <archivo>` | Elimina un archivo (¡sin papelera de reciclaje! `rm -r` para directorios) |
| `clear` | Limpia la pantalla de la terminal |

### Pedir ayuda al sistema (más importante que memorizar)

En vez de memorizar cada flag de cada comando, el sistema tiene documentación integrada:

```bash
man ls        # abre el manual completo de "ls" (salís con "q")
ls --help     # ayuda rápida y resumida
```

**Esto es una habilidad central del curso:** un administrador de sistemas experimentado no memoriza cientos de flags — sabe **cómo encontrar la respuesta rápido**. `man` va a ser tu primera parada siempre que dudes de un comando.

---

## 5. CÓMO FUNCIONA: variables de entorno

Una **variable de entorno** es un valor con nombre que el shell y los programas pueden leer para comportarse de cierta forma. Ya viste una: `PATH`.

```bash
# Ver todas las variables de entorno activas
env

# Ver una variable específica
echo $HOME
echo $USER
echo $SHELL

# Crear una variable temporal (solo dura esta sesión de terminal)
MI_VARIABLE="hola"
echo $MI_VARIABLE
```

**Por qué existen:** permiten que los programas se configuren sin tener que editar código o archivos de configuración cada vez. Por ejemplo, `$HOME` le dice a cualquier programa "esta es la carpeta personal del usuario actual", sin que el programa tenga que preguntarlo.

Las variables que definís así con `MI_VARIABLE="hola"` desaparecen cuando cerrás la terminal. Cómo hacerlas permanentes es algo que vas a ver en el Módulo 17 (Bash profesional), cuando entiendas los archivos de configuración del shell (`.bashrc`).

---

## 6. EJEMPLO

Secuencia real de exploración, para que veas los conceptos encadenados:

```bash
pwd                     # ¿dónde estoy?
ls -la                  # ¿qué hay acá, incluyendo ocultos?
cd /etc                 # me muevo a la carpeta de configuración del sistema
pwd                     # confirmo que me moví
ls | wc -l              # cuento cuántos archivos/carpetas hay en /etc (adelanto de pipes, Módulo 03)
cd ~                    # vuelvo a mi home
man cd                  # ¿qué dice el manual sobre "cd"? (vas a ver que es un built-in del shell, no un programa aparte)
```

---

## 7. PRÁCTICA

En tu VM de Arch Linux, ejecutá y anotá el resultado de:

1. `pwd` al abrir la terminal — ¿en qué directorio arrancás por defecto?
2. `echo $HOME` y `echo $USER` — ¿coinciden con el usuario que usaste para iniciar sesión?
3. Navegá a `/var/log` con `cd`, listá su contenido con `ls -la`, y volvé a tu home con `cd ~`.
4. Creá un directorio de prueba: `mkdir ~/lab01`, entrá con `cd ~/lab01`, creá un archivo vacío `touch prueba.txt`, y confirmá que existe con `ls -la`.
5. Ejecutá `echo $PATH` y contá cuántas carpetas distintas aparecen (separadas por `:`).
6. Abrí `man ls`, buscá qué hace la opción `-h` (pista: tiene que ver con tamaños de archivo legibles), y salí con `q`.

---

## 8. ERROR INTENCIONAL (mini Break & Fix)

Vas a provocar un error común y aprender a leerlo, no solo a evitarlo.

```bash
cd /home/usuario_que_no_existe_12345
```

Vas a obtener algo como:

```
bash: cd: /home/usuario_que_no_existe_12345: No such file or directory
```

Ahora probá también:

```bash
ls -z
```

Vas a obtener un error distinto, relacionado con una opción inválida.

---

## 9. DIAGNÓSTICO

Para el primer error:

- **Síntoma:** `No such file or directory`.
- **Causa raíz:** le pediste al shell que entre a una ruta que no existe en el filesystem.
- **Cómo se diagnostica en general:** este tipo de mensaje siempre significa que **la ruta especificada no existe tal cual la escribiste** — puede ser un error de tipeo, mayúsculas/minúsculas (Linux distingue entre mayúsculas y minúsculas, a diferencia de Windows), o que el directorio realmente no fue creado todavía.

Para el segundo error:

- **Síntoma:** algo como `ls: invalid option -- 'z'` seguido de una sugerencia de usar `--help`.
- **Causa raíz:** `-z` no es una opción reconocida por `ls`.
- **Cómo se diagnostica:** cuando un programa no reconoce una opción, casi siempre te dice explícitamente cuál fue el problema y te sugiere consultar la ayuda. **Leer el mensaje de error completo, no solo la primera línea, es una habilidad que vas a usar constantemente en este curso.**

---

## 10. SOLUCIÓN

- Para el primer error: usar `ls /home` para ver qué usuarios existen realmente, y corregir la ruta.
- Para el segundo: `ls --help | grep -i tamaño` (o en inglés, `size`) para encontrar la opción correcta (es `-h`, combinada con `-l`, es decir `ls -lh`).

---

## 11. RETO

Sin buscar en internet:

1. Explicá con tus palabras por qué `cd` no aparece cuando hacés `which cd` (pista: `cd` es un "comando interno" del shell, no un programa separado en el disco — investigalo con `type cd`).
2. ¿Qué pasaría si borraras (hipotéticamente, no lo hagas) una carpeta que está listada en tu `$PATH`? ¿Qué comandos dejarían de funcionar y por qué?
3. Usando lo que aprendiste de `man`, buscá qué hace la opción `-R` de `ls` y explicá con tus palabras para qué serviría en un caso real de administración de sistemas.

---

## Checklist de cierre del módulo

- [ ] Explico la diferencia entre terminal y shell.
- [ ] Entiendo la estructura programa + opciones + argumentos.
- [ ] Sé usar `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm`.
- [ ] Sé consultar `man` y `--help` en vez de memorizar todo.
- [ ] Entiendo qué es una variable de entorno y para qué sirve `$PATH`.
- [ ] Completé la práctica y el error intencional en mi propia VM.
- [ ] Respondí las 3 preguntas del reto.

---

**Próximo módulo:** 02 — Filesystem de Linux (Fase I — Linux Fundamentals).
