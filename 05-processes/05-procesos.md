# Módulo 05 — Procesos

**Fase I — Linux Fundamentals**

Con este módulo cerramos la Fase I.

---

## Objetivos del módulo

- Entender qué es un proceso y cómo el kernel los gestiona.
- Diferenciar procesos en primer plano, segundo plano y demonios (daemons).
- Usar herramientas para observar, priorizar y terminar procesos.
- Entender señales (`SIGTERM`, `SIGKILL`, etc.) y por qué existen distintos "tipos de matar" un proceso.
- Cerrar la Fase I con una vista completa: terminal → filesystem → texto → permisos → procesos, todo conectado.

---

## 1. CONCEPTO: ¿qué es un proceso?

Un **proceso** es un programa en ejecución: código cargado en memoria, con su propio espacio de memoria, su propio PID (identificador numérico único), y un usuario dueño (el que lo ejecutó). Cuando corriste `ls`, `cat`, o cualquier comando en los módulos anteriores, cada uno se convirtió en un proceso mientras corría, y desapareció al terminar.

El kernel Linux es responsable de **crear procesos, darles tiempo de CPU (scheduling), aislarlos entre sí en memoria, y destruirlos cuando terminan**. Esto conecta directo con el Módulo 00: el kernel es el gestor de recursos, y los procesos son la unidad básica de "trabajo" que gestiona.

---

## 2. POR QUÉ EXISTE: multitarea y aislamiento

### El problema que resuelve

Una CPU (o núcleo) físicamente solo puede ejecutar una instrucción a la vez. Sin embargo, tu sistema corre decenas o cientos de procesos "simultáneamente" (tu shell, systemd, servicios de red, etc.). Esto se logra porque el kernel reparte el tiempo de CPU en fracciones muy pequeñas (milisegundos) entre todos los procesos activos, dando la ilusión de simultaneidad — esto se llama **scheduling** (planificación).

### Por qué los procesos están aislados entre sí

Cada proceso tiene su propio espacio de memoria virtual, separado del resto. Esto significa que un proceso no puede (normalmente) leer ni corromper la memoria de otro proceso por accidente ni intencionalmente. Si un programa se cuelga o tiene un bug, en principio no debería poder arrastrar a los demás procesos con él. Esta es una de las razones por las que Linux es tan estable frente a fallos de programas individuales.

---

## 3. CÓMO FUNCIONA: primer plano, segundo plano y demonios

### Primer plano (foreground)

Cuando ejecutás un comando normal, ocupa tu terminal hasta que termina:

```bash
sleep 30    # tu terminal queda "bloqueada" 30 segundos
```

### Segundo plano (background)

Agregando `&` al final, el comando corre pero te devuelve el control de la terminal inmediatamente:

```bash
sleep 30 &     # corre en background, podés seguir usando la terminal
jobs            # lista los procesos en background de esta sesión
fg %1            # trae el job 1 de vuelta a primer plano
```

### Demonios (daemons)

Un **daemon** es un proceso que corre en segundo plano de forma permanente, generalmente iniciado por el sistema (no por un usuario interactivo), sin terminal asociada. Ejemplos: el propio `systemd` (PID 1), servidores web, `sshd` (el servidor SSH que vas a usar en el Módulo 13). Vas a gestionarlos formalmente con `systemctl` en el Módulo 09.

---

## 4. CÓMO FUNCIONA: señales

Un proceso puede recibir **señales**: mensajes cortos del kernel o de otros procesos que le piden hacer algo (generalmente, terminar de cierta forma).

| Señal | Número | Qué significa |
|---|---|---|
| `SIGTERM` | 15 | "Por favor, terminá de forma ordenada" (el proceso puede capturarla y limpiar antes de salir) — es la señal por defecto de `kill` |
| `SIGKILL` | 9 | "Terminá YA, sin excepciones" — el kernel lo mata inmediatamente, el proceso no puede ni reaccionar ni limpiar nada |
| `SIGINT` | 2 | Lo que se envía cuando apretás `Ctrl+C` en la terminal |
| `SIGHUP` | 1 | Tradicionalmente: "tu terminal se cerró"; muchos daemons lo reinterpretan como "recargá tu configuración" |

**Por qué existe esta distinción (`SIGTERM` vs `SIGKILL`):** un proceso bien diseñado, al recibir `SIGTERM`, puede cerrar archivos abiertos, guardar su estado, avisar a otros sistemas, etc., antes de salir — un cierre "limpio". `SIGKILL` es la opción nuclear cuando el proceso está colgado y ni siquiera responde a `SIGTERM`: el kernel lo elimina de memoria sin darle oportunidad de reaccionar. **Siempre probá `SIGTERM` primero**; usar `SIGKILL` de entrada puede dejar archivos corruptos o recursos sin liberar correctamente.

---

## 5. HERRAMIENTA: observar y controlar procesos

```bash
ps aux                  # snapshot de TODOS los procesos del sistema, en este momento
ps aux | grep bash       # filtrar por nombre (patrón que ya usaste en el Módulo 03)
top                       # vista en vivo, actualizada, de procesos y uso de CPU/RAM (salís con "q")
htop                      # versión más amigable de "top" (si está instalado; si no, "top" alcanza por ahora)

pgrep firefox             # buscar el/los PID de un proceso por nombre
pidof firefox              # similar, otra forma de obtener el PID

kill <PID>                 # envía SIGTERM (pedido educado de terminar) a un PID específico
kill -9 <PID>               # envía SIGKILL (forzado) a un PID específico
killall nombre-proceso       # mata todos los procesos que coincidan con ese nombre

nice -n 10 comando            # ejecuta un comando con menor prioridad de CPU
renice 10 -p <PID>             # cambia la prioridad de un proceso ya corriendo
```

### Leyendo `ps aux`

```
USER   PID  %CPU  %MEM  VSZ   RSS   TTY   STAT  START  TIME  COMMAND
```

- **PID** → identificador único del proceso.
- **%CPU / %MEM** → cuánto está usando ahora mismo.
- **STAT** → estado: `R` (corriendo), `S` (durmiendo, esperando algo), `Z` (zombie — terminó pero su "espacio" no fue limpiado por su proceso padre, algo a investigar si se acumulan).
- **COMMAND** → qué comando lo originó.

---

## 6. EJEMPLO

```bash
# Lanzar un proceso de prueba en background
sleep 300 &
jobs                    # ver que está corriendo como job 1
ps aux | grep sleep      # verlo también desde ps, con su PID real

# Terminarlo de forma ordenada
kill %1                  # usando el número de job
# o, alternativamente:
pkill sleep               # matarlo por nombre directamente
```

---

## 7. PRÁCTICA

1. `ps aux | wc -l` — ¿cuántos procesos hay corriendo en total en tu sistema ahora?
2. `ps aux | grep bash` — ¿ves tu propia sesión de shell listada?
3. Ejecutá `sleep 120 &`, después `jobs`, y luego `kill %1` — confirmá con `jobs` de nuevo que ya no aparece.
4. `top` — dejalo abierto 10 segundos mirando qué proceso consume más CPU, y salí con `q`. Contame qué proceso viste arriba de la lista.
5. `pgrep bash` — ¿qué PID(s) te devuelve? Compará con lo que viste en el punto 2.

---

## 8. ERROR INTENCIONAL (Break & Fix simulado)

```bash
sleep 500 &
kill -9 %1
```

Después intentá:

```bash
kill %1
```

---

## 9. DIAGNÓSTICO

El segundo `kill %1` te va a dar algo como `bash: kill: %1: no such job` — porque el proceso ya fue eliminado por el `SIGKILL` anterior; el número de job ya no existe. Esto ilustra que `SIGKILL` no deja rastro ni posibilidad de "arrepentirse": el proceso desaparece instantáneamente de la tabla de procesos, sin importar en qué estaba haciendo en ese momento.

## 10. SOLUCIÓN / conclusión práctica

Como regla operativa para el resto del curso:

1. Probá siempre `kill <PID>` (SIGTERM) primero.
2. Esperá unos segundos — muchos programas necesitan un instante para cerrar limpiamente.
3. Solo si el proceso sigue vivo (`ps aux | grep <PID>` todavía lo muestra), escalá a `kill -9 <PID>`.

Vas a aplicar exactamente este criterio en el laboratorio Break & Fix #4 ("Servicio systemd caído") más adelante en el curso.

---

## Checklist de cierre del módulo (y de la Fase I completa)

- [ ] Entiendo qué es un proceso y por qué el kernel gestiona el tiempo de CPU entre ellos.
- [ ] Sé diferenciar foreground, background y daemons.
- [ ] Entiendo la diferencia entre `SIGTERM` y `SIGKILL`, y cuándo usar cada uno.
- [ ] Sé usar `ps aux`, `top`, `kill`, `pgrep`.
- [ ] Completé la práctica y el error intencional en mi VM.

---

## Cierre de Fase I — Linux Fundamentals

Con este módulo terminás la Fase I completa: terminal/shell, filesystem, procesamiento de texto, usuarios/permisos y procesos. Estos cinco módulos son la base sobre la que se apoya **todo** lo que sigue — desde acá en adelante, cada módulo nuevo va a asumir que estos comandos y conceptos ya son naturales para vos.

Según el sistema de evaluación de la guía, correspondería ahora una evaluación de fase (preguntas conceptuales + ejercicio de troubleshooting + mini-proyecto). Se puede hacer antes de arrancar la Fase II, o seguir directo — como quieras.

---

**Próximo módulo:** 06 — Instalación profesional de Arch Linux (inicio de la Fase II — Arch Linux Core).
