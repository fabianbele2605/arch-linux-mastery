# Módulo 00 — Fundamentos de computación

**Fase 0 — Fundamentos**

---

## Objetivos del módulo

Al terminar este módulo vas a poder explicar, sin recurrir a analogías vagas:

- Qué hace realmente un procesador (CPU) cuando "ejecuta" un programa.
- Cómo se relacionan CPU, RAM y almacenamiento persistente (disco).
- Qué es el firmware (BIOS/UEFI) y por qué existe antes que cualquier sistema operativo.
- Qué hace un sistema operativo y por qué Linux es un kernel, no un SO completo por sí solo.
- Qué es una VM (máquina virtual) y por qué VirtualBox te permite correr Arch Linux dentro de tu sistema actual.

Esto es la base que necesitás antes de tocar una terminal de Linux. Sin esto, comandos como `mount`, `lsblk` o `systemctl` son magia memorizada, no herramientas entendidas.

---

## 1. CONCEPTO: ¿Qué es una computadora, en términos operativos?

Una computadora es una máquina que:

1. **Almacena instrucciones y datos** en memoria (binario: ceros y unos).
2. **Ejecuta instrucciones** una tras otra (con excepciones: saltos, interrupciones, paralelismo).
3. **Se comunica con el mundo exterior** (teclado, pantalla, red, disco) a través de dispositivos controlados por el sistema operativo.

Todo lo que hace un sistema —desde mostrar una ventana hasta enviar un paquete de red— se reduce, en el fondo, a estas tres cosas ejecutándose en bucle, miles de millones de veces por segundo.

---

## 2. POR QUÉ EXISTE: la jerarquía CPU → RAM → Disco

### Por qué no hay un solo tipo de memoria

Si existiera una sola memoria "perfecta" (rápida, grande y barata a la vez), no necesitaríamos esta jerarquía. No existe. Hay un trade-off físico ineludible: **velocidad vs. capacidad vs. costo vs. persistencia**. Por eso el hardware se organiza en capas:

```
┌─────────────────────────────────────────────┐
│  CPU (registros, caché L1/L2/L3)             │  ← más rápido, más caro, más pequeño
│  Volátil. Se pierde al apagar.                │
├─────────────────────────────────────────────┤
│  RAM (memoria principal)                      │
│  Volátil. Se pierde al apagar.                │
│  Rápida, pero limitada en tamaño (GB).        │
├─────────────────────────────────────────────┤
│  Almacenamiento persistente (SSD/HDD)         │  ← más lento, más barato, más grande
│  No volátil. Sobrevive al apagado.            │
│  Aquí vive tu sistema operativo y archivos.   │
└─────────────────────────────────────────────┘
```

**Por qué existe esto:** la CPU necesita datos disponibles casi instantáneamente para no quedarse "esperando". La RAM es un compromiso: mucho más rápida que un disco, pero se borra al apagar. El disco es lo opuesto: lento, pero conserva los datos sin energía. Ningún sistema operativo puede eliminar esta jerarquía; solo puede gestionarla mejor (esto es, en parte, lo que hace el kernel de Linux con la memoria virtual y el caché de página, temas que verás en el módulo de Kernel).

### Consecuencia práctica

Cuando encendés tu computadora, la RAM está vacía. El sistema operativo no "aparece" solo: alguien tiene que **cargarlo desde el disco hacia la RAM** y ponerlo a correr en la CPU. Ese "alguien" es el firmware y el bootloader — lo vas a ver en detalle en el Módulo 10 (Boot), pero necesitás la idea ahora.

---

## 3. CÓMO FUNCIONA: firmware, arranque y sistema operativo

### 3.1 Firmware (BIOS / UEFI)

Antes de que exista cualquier sistema operativo, hay un programa mínimo grabado en un chip de la placa base: el **firmware**. Los dos estándares que vas a encontrar:

| | BIOS (legado) | UEFI (moderno) |
|---|---|---|
| Año | Desde los 80 | Estándar desde ~2010 en adelante |
| Tabla de particiones que usa | MBR | GPT (soporta también MBR) |
| Capacidades | Muy limitado, 16-bit | Puede correr código más complejo, tiene su propio "mini sistema de archivos" (ESP) |
| Arch Linux hoy | Compatible, pero en retroceso | Estándar recomendado |

**Por qué importa para vos:** cuando instales Arch Linux (Módulo 06), vas a tener que decidir consciente y explícitamente si tu VM usa BIOS o UEFI, porque cambia completamente cómo particionás el disco y qué bootloader usás. VirtualBox permite elegir esto al crear la VM (hay una opción de "Enable EFI").

### 3.2 ¿Qué hace el firmware?

Su única tarea es: **encontrar un dispositivo de arranque válido, cargar el primer programa que encuentre ahí, y cederle el control.** Ese "primer programa" es el bootloader (ej: GRUB o systemd-boot), y lo vas a estudiar en profundidad en el Módulo 10.

El firmware no sabe nada de "Linux", "Windows" ni "archivos". Solo sabe seguir un procedimiento estandarizado para arrancar algo.

### 3.3 ¿Qué es un sistema operativo?

Un sistema operativo es el software que:

1. **Gestiona el hardware** (CPU, memoria, disco, red, periféricos) para que los programas no tengan que hablar directamente con cada pieza física.
2. **Aísla y coordina procesos**, para que múltiples programas puedan correr "a la vez" sin pisarse.
3. **Expone una interfaz** (comandos, llamadas al sistema / syscalls) para que los programas pidan recursos de forma controlada.

### 3.4 Kernel vs. sistema operativo completo

Este es un punto que mucha gente confunde y que es clave para entender qué es Arch Linux:

- **Linux** es un **kernel**: el núcleo que gestiona CPU, memoria, procesos, dispositivos y el sistema de archivos a bajo nivel.
- **Arch Linux** (la distribución) es el kernel Linux **más** un conjunto de herramientas: gestor de paquetes (pacman), sistema de inicio (systemd), shell, utilidades básicas (coreutils), etc.

Esto explica por qué existen tantas "distros" distintas (Arch, Debian, Fedora...) usando el mismo kernel: cada una empaqueta y configura ese kernel con un conjunto diferente de herramientas y filosofía. Arch se caracteriza por ser minimalista: no instala nada que no pediste explícitamente, y te obliga a entender lo que estás configurando (de ahí que el curso use Arch como laboratorio: no te deja "no saber" lo que tenés instalado).

---

## 4. CÓMO FUNCIONA: virtualización (por qué VirtualBox te permite correr Arch dentro de tu sistema)

### Concepto

Un **hipervisor** (VirtualBox, QEMU/KVM, VMware) es software que crea una o más "computadoras falsas" (máquinas virtuales) dentro de una computadora física real, engañando a cada VM para que crea que tiene su propia CPU, RAM, disco y red dedicados.

```
┌───────────────────────────────────────────────┐
│           Hardware físico (tu PC/laptop)       │
├───────────────────────────────────────────────┤
│     Sistema operativo anfitrión (host)         │
│           (ej: Windows, macOS, Linux)          │
├───────────────────────────────────────────────┤
│              Hipervisor (VirtualBox)           │
├──────────────────┬──────────────────────────────┤
│   VM: Arch Linux │   VM: otra distro (opcional) │
│   (huésped/guest)│                              │
└──────────────────┴──────────────────────────────┘
```

**Por qué existe:** te permite romper, reinstalar y experimentar con Arch Linux sin arriesgar tu sistema anfitrión. Es exactamente la razón por la que este curso lo exige como prerrequisito: los laboratorios "Break & Fix" (Módulo de recuperación, incidentes simulados) requieren que puedas destruir intencionalmente el sistema y no haya consecuencias reales.

### Snapshots — tu red de seguridad

VirtualBox permite tomar "snapshots" (fotos del estado completo de la VM) y volver a ellas cuando algo salga mal. **Esto es fundamental para este curso**: antes de cada laboratorio "Break & Fix", vas a tomar un snapshot. Si rompés algo más allá de lo que podés reparar, volvés al snapshot y listo.

---

## 5. HERRAMIENTA: identificar estos conceptos en tu propia VM

No vamos a instalar nada todavía (eso es el Módulo 06). Pero como ya tenés Arch corriendo, podés observar estos conceptos ahora mismo.

### Comandos para observar (no memorizar, solo ejecutar y mirar el resultado)

```bash
# Ver información de la CPU virtualizada
lscpu

# Ver la memoria RAM asignada a la VM
free -h

# Ver los discos que ve tu sistema
lsblk

# Ver si tu sistema arrancó en modo UEFI o BIOS
ls /sys/firmware/efi 2>/dev/null && echo "Arrancaste en modo UEFI" || echo "Arrancaste en modo BIOS (legacy)"

# Ver la versión del kernel que estás corriendo
uname -r
```

No te preocupes si no entendés la sintaxis todavía — la terminal y el shell son el Módulo 01. Acá el objetivo es solo **conectar los conceptos teóricos con algo real y visible en tu pantalla**.

---

## 6. EJEMPLO

Ejecutá `lscpu` en tu VM y fijate en la línea `CPU(s):`. Ese número no es necesariamente el número de núcleos físicos de tu laptop/PC — es cuántos núcleos **le asignaste a la VM** en la configuración de VirtualBox. Esto ilustra directamente el concepto de virtualización: VirtualBox le presenta a Arch Linux un hardware "virtual" que vos definiste, no el hardware físico completo de tu máquina.

---

## 7. PRÁCTICA

Abrí tu terminal en Arch Linux (dentro de la VM) y ejecutá los 5 comandos de la sección "Herramienta". Anotá (en un archivo de texto, en papel, donde quieras) las respuestas a esto:

1. ¿Cuántos CPUs virtuales tiene asignada tu VM?
2. ¿Cuánta RAM tiene asignada?
3. ¿Tu VM arrancó en modo UEFI o BIOS?
4. ¿Qué versión de kernel Linux estás corriendo?
5. ¿Cuántos discos (`lsblk`) ve tu sistema, y qué tamaño tienen?

---

## 8. ERROR INTENCIONAL

Este primer módulo no tiene un laboratorio "Break & Fix" (esos empiezan más adelante, cuando ya tengas sistema de archivos y servicios que romper). En su lugar, hacé este ejercicio de diagnóstico conceptual:

**Situación simulada:** Encendés tu VM de VirtualBox y la pantalla se queda en negro, sin ningún mensaje, indefinidamente.

Preguntate, en orden:

1. ¿El problema está en el firmware (la VM ni siquiera llega a mostrar el splash de arranque), en el bootloader (arranca pero no encuentra el sistema), o en el kernel/sistema operativo (arranca el bootloader pero el sistema no continúa)?
2. ¿Cómo diferenciarías estos tres casos con lo que aprendiste en este módulo, **sin ejecutar ningún comando todavía**, solo mirando qué aparece en pantalla?

Esto es intencional: en este módulo no tenés las herramientas todavía para resolverlo técnicamente (eso viene en el Módulo 10 — Boot y el Módulo 16 — Recuperación). El objetivo es que **empieces a pensar en capas** (firmware → bootloader → kernel → sistema operativo) al diagnosticar, en vez de "probar comandos al azar".

---

## 9. DIAGNÓSTICO Y SOLUCIÓN

Guía de razonamiento para el escenario anterior:

| Síntoma en pantalla | Capa probable del problema |
|---|---|
| Nada, ni el logo de VirtualBox/EFI | Configuración de la VM (RAM/CPU insuficiente, disco no conectado) |
| Aparece el firmware (logo UEFI o mensaje BIOS) pero no avanza | Firmware no encuentra dispositivo de arranque válido |
| Aparece un menú (GRUB) pero falla al seleccionar Arch | Problema de bootloader — Módulo 10 |
| Arranca pero se cuelga con mensajes de kernel (texto técnico) | Problema de kernel/initramfs — Módulo 10 y 16 |

No necesitás memorizar esta tabla ahora. Volvé a ella cuando llegues al Módulo 10 y 16 — ahí vas a tener las herramientas (`journalctl`, `dmesg`, modo de rescate) para aplicar este razonamiento con comandos reales.

---

## 10. RETO

Sin buscar en internet todavía (excepto si es estrictamente necesario), respondé por escrito, con tus propias palabras:

1. ¿Por qué no existe una sola memoria que sea rápida, grande, barata y persistente a la vez? (Pensalo en términos de qué estarías dispuesto a sacrificar vos si tuvieras que diseñar un chip de memoria).
2. ¿Por qué decimos que "Linux" es un kernel y no un sistema operativo completo? Dá un ejemplo de dos cosas que una distribución (como Arch) agrega *sobre* el kernel.
3. En tus propias palabras: ¿qué diferencia hay entre el firmware, el bootloader y el kernel? Ordenalos según el momento en que actúan al encender la computadora.

---

## Checklist de cierre del módulo

- [ ] Puedo explicar la jerarquía CPU → RAM → Disco y por qué existe.
- [ ] Sé si mi VM arrancó en modo BIOS o UEFI, y sé qué comando lo verifica.
- [ ] Entiendo la diferencia entre kernel y sistema operativo completo.
- [ ] Entiendo qué es un hipervisor y por qué uso snapshots antes de romper cosas.
- [ ] Ejecuté los 5 comandos de la sección "Herramienta" en mi propia VM y anoté los resultados.
- [ ] Respondí las 3 preguntas del reto por escrito.

---

**Próximo módulo:** 01 — Terminal y shell (Fase I — Linux Fundamentals).
