# Módulo 03 — Texto y procesamiento (pipes, redirecciones)

**Fase I — Linux Fundamentals**

---

## Objetivos del módulo

- Entender qué son stdin, stdout y stderr (los tres canales estándar de todo programa).
- Usar redirecciones (`>`, `>>`, `<`, `2>`) para controlar entrada/salida.
- Usar pipes (`|`) para encadenar comandos — la herramienta más poderosa del shell.
- Manejar las herramientas clásicas de procesamiento de texto: `grep`, `sort`, `uniq`, `wc`, `cut`, `awk` (básico), `sed` (básico).

---

## 1. CONCEPTO: los tres canales estándar

Todo programa que corre en Linux tiene, por defecto, tres "tuberías" de comunicación:

| Canal | Nombre | Número | Uso |
|---|---|---|---|
| stdin | entrada estándar | 0 | de dónde el programa lee datos (por defecto: el teclado) |
| stdout | salida estándar | 1 | dónde el programa escribe sus resultados normales (por defecto: la pantalla) |
| stderr | salida de error | 2 | dónde el programa escribe sus mensajes de error (por defecto: también la pantalla) |

**Por qué existen separados stdout y stderr:** si estuvieran mezclados, sería imposible procesar automáticamente solo los resultados "buenos" de un comando sin que se cuelen los errores (o viceversa). Esta separación es la base de por qué el shell es tan potente para automatización: podés redirigir cada canal a un lugar distinto.

---

## 2. POR QUÉ EXISTE: la filosofía Unix de "programas pequeños que hacen una cosa bien"

Linux (heredero de Unix) no tiene un único programa gigante que "haga de todo". Tiene muchos programas pequeños, cada uno especializado (`grep` busca texto, `sort` ordena, `wc` cuenta), y el mecanismo para combinarlos es el **pipe**.

Esto resuelve un problema real: en vez de que cada autor de software tenga que reinventar "buscar + ordenar + contar" dentro de su propio programa, cualquier programa que respete stdin/stdout puede combinarse con cualquier otro. Es composición, no reinvención.

---

## 3. CÓMO FUNCIONA: redirecciones

```bash
comando > archivo.txt     # redirige stdout a un archivo (lo SOBRESCRIBE)
comando >> archivo.txt    # redirige stdout a un archivo (AGREGA al final)
comando < archivo.txt     # usa un archivo como entrada (stdin) del comando
comando 2> errores.txt    # redirige solo stderr a un archivo
comando > salida.txt 2>&1 # redirige stdout Y stderr al mismo archivo
comando 2>/dev/null       # descarta los errores (los manda a "la nada")
```

`/dev/null` es un archivo especial que existe siempre en Linux y que descarta todo lo que se le escribe — es literalmente "el vacío" del sistema, y lo vas a usar todo el curso para silenciar salidas que no te interesan.

---

## 4. CÓMO FUNCIONA: pipes (`|`)

Un pipe conecta el **stdout** de un comando con el **stdin** del siguiente, formando una cadena de procesamiento:

```bash
comando1 | comando2 | comando3
```

Cada comando procesa lo que le llega y pasa el resultado al siguiente, sin necesidad de archivos intermedios.

### Ejemplo real y explicado

```bash
cat /etc/passwd | grep bash | wc -l
```

- `cat /etc/passwd` → vuelca el contenido completo del archivo de usuarios.
- `| grep bash` → de esas líneas, se queda solo con las que contienen la palabra "bash" (usuarios cuyo shell por defecto es bash).
- `| wc -l` → cuenta cuántas líneas quedaron, es decir, cuántos usuarios tienen bash como shell.

Fijate que ninguno de los tres programas (`cat`, `grep`, `wc`) "sabe" de los otros dos — cada uno solo lee de su stdin y escribe a su stdout. El pipe es lo que los conecta.

---

## 5. HERRAMIENTA: comandos de procesamiento de texto

```bash
grep "patron" archivo        # busca líneas que contienen "patron"
grep -i "patron" archivo      # ignora mayúsculas/minúsculas
grep -r "patron" carpeta/     # busca recursivamente en toda una carpeta
grep -v "patron" archivo      # muestra las líneas que NO contienen "patron" (inverso)

sort archivo                  # ordena líneas alfabéticamente
sort -n archivo                # ordena numéricamente
sort -r archivo                # orden inverso

uniq                            # elimina líneas duplicadas CONSECUTIVAS (se usa casi siempre con sort antes)
sort archivo | uniq             # patrón clásico: ordenar y luego deduplicar

wc -l archivo                  # cuenta líneas
wc -w archivo                  # cuenta palabras
wc -c archivo                  # cuenta caracteres/bytes

cut -d ":" -f1 /etc/passwd     # corta cada línea por el delimitador ":" y muestra el campo 1

awk -F ":" '{print $1}' /etc/passwd   # equivalente más potente a cut, con lenguaje propio
sed 's/viejo/nuevo/' archivo          # reemplaza texto (sustitución básica)
```

No necesitás dominar `awk` y `sed` a fondo todavía — son herramientas que tienen su propio "mini lenguaje" y las vas a ir profundizando con la práctica. Por ahora, reconocé el patrón: **buscar → transformar → contar/ordenar**, encadenado con pipes.

---

## 6. EJEMPLO

```bash
# ¿Cuántos usuarios existen en el sistema y cuáles usan bash?
cat /etc/passwd | wc -l
cat /etc/passwd | grep bash

# ¿Qué procesos está corriendo tu usuario, ordenados?
ps aux | grep fabian | sort

# Guardar en un archivo solo los errores de un comando, y ver la salida normal en pantalla
ls /etc /carpeta-que-no-existe > salida_ok.txt 2> solo_errores.txt
cat salida_ok.txt
cat solo_errores.txt
```

---

## 7. PRÁCTICA

Ejecutá y pasame el resultado:

1. `cat /etc/passwd | wc -l` — ¿cuántos usuarios/entradas hay en total?
2. `cat /etc/passwd | cut -d ":" -f1` — lista de nombres de usuario (los primeros 10 alcanzan).
3. `cat /etc/passwd | grep bash | wc -l` — ¿cuántos usuarios tienen bash como shell?
4. Ejecutá `ls /etc /carpeta-inventada > ok.txt 2> err.txt` desde tu home, y después `cat ok.txt` y `cat err.txt` por separado — confirmá que la separación funcionó.
5. `history | tail -n 20 | grep cd` — de tus últimos 20 comandos, ¿cuántos fueron `cd`?

---

## 8. ERROR INTENCIONAL

```bash
cat archivo_que_no_existe.txt | grep algo
```

---

## 9. DIAGNÓSTICO Y SOLUCIÓN

`cat` va a fallar con `No such file or directory` — pero fijate que **el pipe igual "funciona"**: `grep` se ejecuta con una entrada vacía (porque `cat` no produjo stdout), así que simplemente no muestra nada, sin error propio. Esto ilustra algo importante: un pipe no "sabe" si el comando anterior falló — solo conecta stdout con stdin. Si necesitás saber si un comando en medio de una cadena falló, hay mecanismos (`set -o pipefail`, `$?`) que vas a ver en el Módulo 17 (Bash profesional).

**Solución:** verificar primero que el archivo existe (`ls archivo_que_no_existe.txt`) antes de asumir que un pipe vacío significa "no hay resultados que coincidan".

---

## Checklist de cierre del módulo

- [ ] Entiendo stdin, stdout, stderr y por qué están separados.
- [ ] Sé usar `>`, `>>`, `<`, `2>`, `2>&1`, `/dev/null`.
- [ ] Entiendo y uso pipes para encadenar comandos.
- [ ] Sé usar `grep`, `sort`, `uniq`, `wc`, `cut` en combinación.
- [ ] Completé la práctica en mi VM.

---

**Próximo módulo:** 04 — Usuarios y permisos.
