# Módulo 22 — Kernel Linux

**Fase V — Infrastructure & Advanced Systems**

---

## Objetivos del módulo

- Entender la arquitectura del kernel Linux (monolítico con módulos cargables).
- Explorar módulos del kernel: `lsmod`, `modinfo`, `modprobe`, `rmmod`.
- Entender y ajustar parámetros del kernel en tiempo de ejecución con `sysctl`.
- Entender `/proc` y `/sys` como interfaces del kernel hacia espacio de usuario.
- Escribir, compilar y cargar tu propio módulo de kernel ("Hello World" a nivel kernel).

> **Nota sobre el alcance:** compilar un kernel completo desde cero (Proyecto 14 de la guía) puede tardar 30-90 minutos incluso en hardware potente, y bastante más en una VM. En este módulo vas a trabajar con **módulos cargables** (mucho más rápido y seguro de iterar) para entender la mecánica real de extender el kernel; la compilación completa queda como proyecto opcional más adelante, cuando tengas tiempo dedicado para ello.

---

## 1. CONCEPTO: arquitectura del kernel Linux

Linux es un kernel **monolítico modular**: a diferencia de un microkernel (que mueve la mayoría de los servicios fuera del núcleo, a procesos separados), Linux corre la mayor parte de su funcionalidad (filesystems, drivers, red) en un único espacio de memoria privilegiado — pero permite **cargar y descargar partes de esa funcionalidad dinámicamente** como módulos, sin recompilar ni reiniciar.

**Por qué importa esta decisión de diseño:** un monolítico puro sería enorme e inflexible (todo el código de todos los drivers posibles, siempre en memoria). Un microkernel puro sería más "limpio" pero con overhead de comunicación entre procesos. Los módulos cargables de Linux son un punto intermedio: el núcleo core es monolítico (rápido, sin overhead de IPC), pero el sistema es flexible porque podés cargar solo los drivers que tu hardware específico necesita, cuando los necesita.

Ya viste esto en acción sin saberlo: en el Módulo 10, `mkinitcpio` empaquetaba módulos del kernel necesarios para el arranque temprano.

---

## 2. HERRAMIENTA: explorar módulos cargados

```bash
lsmod                     # lista los módulos actualmente cargados
lsmod | wc -l               # ¿cuántos tenés cargados ahora?

modinfo nombre_del_modulo    # información detallada de un módulo (autor, descripción, parámetros)

sudo modprobe nombre_del_modulo   # cargar un módulo (resolviendo dependencias automáticamente)
sudo rmmod nombre_del_modulo       # descargar un módulo

dmesg | tail -20                    # ver mensajes recientes del kernel (ya lo usaste en el Módulo 15)
```

`modprobe` es preferible a `insmod` porque **resuelve dependencias automáticamente** (si el módulo que querés cargar depende de otro, `modprobe` lo carga también; `insmod` no).

---

## 3. CÓMO FUNCIONA: `sysctl` y parámetros del kernel en runtime

El kernel expone cientos de parámetros configurables **sin reiniciar**, a través de `/proc/sys/` y la herramienta `sysctl`.

```bash
sysctl -a | wc -l                       # ¿cuántos parámetros configurables tiene tu kernel?
sysctl net.ipv4.ip_forward                # ver un parámetro específico
cat /proc/sys/net/ipv4/ip_forward           # equivalente directo, leyendo el archivo virtual

sudo sysctl -w net.ipv4.ip_forward=1          # cambiar un parámetro (solo en runtime, se pierde al reiniciar)

# Para que un cambio sea permanente:
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-custom.conf
sudo sysctl --system    # recargar toda la configuración persistente
```

**Conexión con el Módulo 12 (Networking):** `net.ipv4.ip_forward` es exactamente el parámetro que convierte tu sistema en un router (reenvía paquetes entre interfaces) — es el tipo de ajuste de kernel que vas a usar en escenarios reales de redes.

---

## 4. CONCEPTO: `/proc` y `/sys` — el kernel expuesto como archivos

Ya usaste `/proc` indirectamente (Módulo 00: `lscpu` lee de ahí). Son **filesystems virtuales**: no existen en disco, los genera el kernel en tiempo real.

```bash
cat /proc/cpuinfo | head -20      # información de CPU, generada al vuelo
cat /proc/meminfo | head -10        # memoria, en tiempo real
ls /proc/self/                        # información del proceso actual (el propio shell)
cat /sys/class/net/*/address           # direcciones MAC de tus interfaces de red, vía /sys
```

**Por qué existen ambos, con propósitos parecidos:** `/proc` es más viejo y históricamente terminó siendo un poco "cajón de sastre" (información de procesos, pero también parámetros del sistema). `/sys` se diseñó después con una organización más estricta, específicamente para representar el modelo de dispositivos del kernel (buses, drivers, dispositivos). Ambos siguen coexistiendo por compatibilidad.

---

## 5. EJEMPLO: escribir tu propio módulo de kernel ("Hello World" a nivel kernel)

```bash
sudo pacman -S linux-headers base-devel
mkdir ~/proyectos/mi_modulo_kernel
cd ~/proyectos/mi_modulo_kernel
nano hola_kernel.c
```

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("fabian");
MODULE_DESCRIPTION("Mi primer modulo de kernel");

static int __init hola_init(void) {
    printk(KERN_INFO "Hola desde el kernel!\n");
    return 0;
}

static void __exit hola_exit(void) {
    printk(KERN_INFO "Chau desde el kernel!\n");
}

module_init(hola_init);
module_exit(hola_exit);
```

**Diferencia clave con el `hola.c` del Módulo 20:** este código no corre como un programa normal en espacio de usuario — `module_init`/`module_exit` son los puntos de entrada/salida que el kernel llama cuando cargás/descargás el módulo, y `printk` (no `printf`) escribe al **buffer de mensajes del kernel** (el mismo que lee `dmesg`), porque un módulo de kernel no tiene una "terminal" propia a la cual imprimir.

Necesitás un `Makefile` especial para compilarlo contra los headers de tu kernel actual:

```bash
nano Makefile
```

```makefile
obj-m += hola_kernel.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

**Atención:** en un `Makefile`, las líneas de comando (`make -C ...`) **deben empezar con un carácter TAB real**, no espacios — es una de las pocas excepciones donde Linux sí exige tabs específicamente. Si usás `nano` con `set tabstospaces` activado (Módulo 19), vas a tener que desactivarlo temporalmente para este archivo, o insertar el tab manualmente.

```bash
make
sudo insmod hola_kernel.ko
dmesg | tail -5          # deberías ver "Hola desde el kernel!"
lsmod | grep hola
sudo rmmod hola_kernel
dmesg | tail -5           # deberías ver "Chau desde el kernel!"
```

---

## 6. PRÁCTICA

1. `lsmod | wc -l` — ¿cuántos módulos tenés cargados? Elegí uno con `modinfo` y leé su descripción.
2. Probá `sysctl net.ipv4.ip_forward` y `cat /proc/sys/net/ipv4/ip_forward` — confirmá que dan el mismo resultado.
3. Explorá `/proc/cpuinfo` y `/proc/meminfo` — compará con lo que viste en el Módulo 00 con `lscpu`/`free -h`.
4. Escribí, compilá y cargá tu propio módulo de kernel de la sección 5. Confirmá los mensajes en `dmesg` al cargarlo y descargarlo.

---

## 7. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
sudo rmmod modulo_que_no_existe
```

**Diagnóstico:** vas a obtener `ERROR: Module modulo_que_no_existe is not currently loaded` — el kernel mantiene registro exacto de qué está cargado, y se niega a intentar descargar algo que no reconoce. Compará esto con la sección 7 del Módulo 09: mismo principio de "el sistema protege contra operaciones sobre algo que no existe", aplicado ahora al nivel más bajo del sistema.

**Otro error común:** si tu `Makefile` no tiene el TAB correcto, `make` va a fallar con `Makefile:X: *** missing separator. Stop.` — un mensaje bastante críptico la primera vez que lo ves, pero que siempre significa exactamente eso: falta un tab donde debería haber uno.

---

## Checklist de cierre del módulo

- [ ] Entiendo por qué Linux es un kernel monolítico modular (no microkernel puro).
- [ ] Sé usar `lsmod`, `modinfo`, `modprobe`, `rmmod`.
- [ ] Sé leer y modificar parámetros del kernel con `sysctl` y `/proc/sys`.
- [ ] Entiendo `/proc` y `/sys` como interfaces del kernel hacia espacio de usuario.
- [ ] Escribí, compilé, cargué y descargué mi propio módulo de kernel, viendo los mensajes en `dmesg`.

---

**Próximo módulo:** 23 — Virtualización (QEMU/KVM/libvirt).
