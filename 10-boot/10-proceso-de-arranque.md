# Módulo 10 — Proceso de arranque (boot)

**Fase II — Arch Linux Core**

> ⚠️ **Antes de empezar este módulo: tomá un snapshot de tu VM en VirtualBox.** Vamos a tocar el bootloader y el initramfs — zonas que, si se rompen mal, pueden dejar tu sistema sin arrancar. Con un snapshot, cualquier error se revierte en segundos. Menú de VirtualBox → Máquina → Tomar instantánea (o desde la ventana del Administrador de VirtualBox).

---

## Objetivos del módulo

- Entender la cadena completa de arranque: firmware → bootloader → kernel → initramfs → systemd.
- Entender GRUB en profundidad (tu caso: BIOS legacy) y su archivo de configuración.
- Entender `mkinitcpio` y el rol del initramfs con más detalle que en el Módulo 06.
- Medir y analizar el tiempo de arranque con `systemd-analyze`.
- Practicar (de forma controlada, con snapshot) el incidente simulado #6 y #7 de la guía: bootloader dañado e initramfs corrupto.

---

## 1. CONCEPTO: la cadena completa de arranque

Ya viste las piezas sueltas en los Módulos 00, 06 y 09. Ahora las conectamos en una sola secuencia:

```
[1] Firmware (BIOS)
      ↓ busca un dispositivo de arranque válido (MBR de sda, en tu caso)
[2] Bootloader (GRUB)
      ↓ muestra menú (si aplica), carga el kernel elegido y su initramfs en RAM
[3] Kernel Linux
      ↓ se descomprime, inicializa hardware básico, monta el initramfs como raíz temporal
[4] initramfs
      ↓ carga los drivers necesarios para acceder al disco real, monta la raíz REAL (sda2)
[5] systemd (PID 1)
      ↓ arranca desde la raíz real, gestiona el resto del arranque (Módulo 09)
[6] Sistema listo (multi-user.target o graphical.target)
```

Cada eslabón depende del anterior. Si falla el paso 2, nunca se llega al 3. Esta cadena es la base de todo el diagnóstico de arranque que vas a hacer en este módulo y en el 16 (Recuperación).

---

## 2. POR QUÉ EXISTE: el problema que resuelve el initramfs

Ya lo mencionamos brevemente en el Módulo 06, ahora profundicemos. El kernel, recién cargado, **no sabe todavía cómo acceder a tu disco real** de forma completa — puede necesitar módulos (drivers) para el controlador de disco, para RAID, LVM, o cifrado, que no están compilados directamente dentro del kernel (para mantenerlo liviano y genérico).

El **initramfs** ("initial RAM filesystem") es un sistema de archivos mínimo, comprimido, cargado directamente en RAM por el bootloader junto al kernel. Contiene justo los módulos y scripts necesarios para:

1. Detectar y activar el hardware de almacenamiento real.
2. Montar la partición raíz real (tu `sda2`).
3. "Pivotear" — transferir el control del sistema desde este filesystem temporal en RAM hacia el sistema real en disco.

**Por qué no arranca directo desde el disco sin este paso intermedio:** porque en el momento en que el kernel arranca, todavía no "sabe" cómo está organizado tu disco específico (¿está cifrado? ¿es RAID? ¿qué controlador usa?). El initramfs es la solución genérica: un sistema mínimo autosuficiente que resuelve ese problema de arranque en frío antes de tocar el sistema real.

---

## 3. CÓMO FUNCIONA: GRUB en modo BIOS (tu caso)

Como confirmamos en el Módulo 00 y 06, arrancás en **BIOS legacy**, así que GRUB se instala en el **MBR** (Master Boot Record, los primeros 446 bytes de `/dev/sda`) más una pequeña zona de "core image" antes de la primera partición.

### Archivos clave

- `/boot/grub/grub.cfg` — el archivo de configuración **generado automáticamente**, nunca se edita a mano.
- `/etc/default/grub` — el archivo que **sí se edita a mano**, con opciones generales (tiempo de espera del menú, parámetros del kernel por defecto, etc.).
- `grub-mkconfig` — el comando que lee `/etc/default/grub` + los kernels instalados en `/boot`, y regenera `grub.cfg`.

```bash
cat /etc/default/grub | grep -v "^#"     # ver opciones activas, sin comentarios
sudo grub-mkconfig -o /boot/grub/grub.cfg   # regenerar la configuración (después de cualquier cambio)
```

**Regla de oro:** nunca edites `grub.cfg` directamente — tus cambios se perderían en la próxima regeneración automática (por ejemplo, al actualizar el kernel, como pasó en el Módulo 07). Siempre editá `/etc/default/grub` y regenerá con `grub-mkconfig`.

---

## 4. CÓMO FUNCIONA: `mkinitcpio` en detalle

```bash
cat /etc/mkinitcpio.conf | grep -v "^#"
```

Vas a ver algo como:
```
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
```

Los **HOOKS** son los pasos que se ejecutan, en orden, para construir el initramfs y para el propio proceso de arranque temprano:
- `base` → funcionalidad esencial.
- `udev` → detección dinámica de dispositivos.
- `autodetect` → optimiza el initramfs incluyendo solo lo que tu hardware actual necesita.
- `block` → soporte para dispositivos de bloque (discos).
- `filesystems` → soporte para tu tipo de filesystem (ext4, en tu caso).
- `fsck` → verificación del filesystem si hace falta.

Regenerar el initramfs (ya lo viste pasar automáticamente en el Módulo 07 al actualizar el kernel):
```bash
sudo mkinitcpio -P     # regenera TODOS los presets configurados (normalmente "default" y "fallback")
```

### La imagen "fallback"

Notá que en `/boot` existen (o deberían existir) dos initramfs: uno normal y uno `-fallback`. El fallback incluye **todos** los módulos posibles (no solo los detectados automágicamente), como red de seguridad si el arranque normal falla por algún driver faltante. GRUB suele ofrecer ambas opciones en su menú ("Advanced options").

---

## 5. HERRAMIENTA: `systemd-analyze` — medir el arranque

```bash
systemd-analyze                 # tiempo total de arranque, desglosado en firmware/loader/kernel/userspace
systemd-analyze blame            # qué servicio tardó más en arrancar, de mayor a menor
systemd-analyze critical-chain    # la cadena de dependencias que determinó el tiempo total de arranque
```

Esto te conecta directo con lo que aprendiste en el Módulo 09: si un servicio tarda demasiado en arrancar, `systemd-analyze blame` te lo señala inmediatamente, sin tener que revisar journal por journal.

---

## 6. PRÁCTICA (sin romper nada todavía)

1. `cat /etc/default/grub | grep -v "^#"` — ¿qué timeout de menú tenés configurado? ¿qué parámetros de kernel por defecto (`GRUB_CMDLINE_LINUX_DEFAULT`)?
2. `ls -lh /boot/` — confirmá que existen `vmlinuz-linux`, `initramfs-linux.img` **e** `initramfs-linux-fallback.img`.
3. `cat /etc/mkinitcpio.conf | grep HOOKS` — listá los hooks configurados.
4. `systemd-analyze` — ¿cuánto tardó tu último arranque en total?
5. `systemd-analyze blame | head -n 10` — ¿qué servicio fue el más lento en arrancar?

---

## 7. ERROR INTENCIONAL — Break & Fix: bootloader dañado (incidente #6 de la guía)

> **Confirmá que ya tomaste el snapshot antes de seguir.**

Vamos a simular un `grub.cfg` corrupto (mucho más seguro y reversible que tocar el MBR directamente):

```bash
sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.backup   # respaldo real, además del snapshot
sudo sh -c 'echo "esto rompe la sintaxis de grub {{{" >> /boot/grub/grub.cfg'
sudo reboot
```

Al reiniciar, GRUB probablemente caiga a su **rescue shell** (un prompt `grub>` mínimo) o falle en mostrar el menú correctamente.

---

## 8. DIAGNÓSTICO

Si quedás en el prompt `grub>` (rescue mode de GRUB), estás en la capa **2** de la cadena de arranque (bootloader), antes incluso de que el kernel se cargue. Esto confirma la utilidad de pensar "en capas" que venimos practicando desde el Módulo 00: firmware funcionó (llegaste hasta acá), pero el bootloader no puede continuar por su configuración corrupta.

## 9. SOLUCIÓN

Si tu VM quedó en un estado no arrancable, la vía más simple y segura es:

```
Restaurar el snapshot de VirtualBox tomado al inicio del módulo.
```

Esto es exactamente la lección de este laboratorio: **el snapshot no es opcional cuando tocás bootloader/initramfs** — es tu red de seguridad real. La reparación "desde adentro" con un medio de arranque live y `arch-chroot` la vas a practicar formalmente en el Módulo 16 (Recuperación de sistemas rotos), que es el módulo diseñado específicamente para reparar sistemas que no arrancan sin recurrir a un snapshot.

**Si preferís restaurar el `grub.cfg` sin reiniciar primero** (más seguro, evitá el `reboot` de arriba si querés jugar seguro):
```bash
sudo cp /boot/grub/grub.cfg.backup /boot/grub/grub.cfg
```

---

## 10. Nota sobre el incidente #7 (initramfs corrupto)

Este incidente es más delicado que el del bootloader — un initramfs corrupto puede dejarte sin ninguna forma de arrancar hasta el kernel, ni siquiera a un rescue shell utilizable. **Lo vamos a practicar formalmente recién en el Módulo 16**, con las herramientas de recuperación (USB/ISO live) ya cubiertas paso a paso, en vez de arriesgarlo ahora sin esa base. Por ahora, quedate con el concepto: si el initramfs falla, el kernel puede arrancar pero no logra montar la raíz real, y vas a ver mensajes como `Unable to find root device` o caer a un `initramfs emergency shell`.

---

## Checklist de cierre del módulo

- [ ] Entiendo la cadena completa: firmware → bootloader → kernel → initramfs → systemd.
- [ ] Sé la diferencia entre `/etc/default/grub` (editable) y `/boot/grub/grub.cfg` (generado).
- [ ] Entiendo qué son los HOOKS de `mkinitcpio` y para qué sirve el initramfs fallback.
- [ ] Sé usar `systemd-analyze` para medir y diagnosticar tiempos de arranque.
- [ ] Completé el laboratorio Break & Fix del bootloader dañado, con snapshot como red de seguridad.
- [ ] Restauré mi sistema (por snapshot o por backup del archivo) a un estado funcional.

---

**Próximo módulo:** 11 — Almacenamiento (particiones, filesystems, LVM, RAID, LUKS).
