# Módulo 06 — Instalación profesional de Arch Linux

**Fase II — Arch Linux Core**

> Nota: como ya tenés Arch Linux instalado y funcionando en tu VM, este módulo se aborda como **teoría completa del proceso de instalación + verificación de cómo quedó configurado tu propio sistema**, en vez de una instalación desde cero. Cada paso del proceso real se acompaña de un comando para comprobar cómo se resolvió en tu instalación actual.

---

## Objetivos del módulo

- Entender cada etapa del proceso de instalación manual de Arch Linux y por qué existe.
- Saber diferenciar particionado MBR/BIOS vs. GPT/UEFI (ya sabemos que tu sistema es BIOS legacy).
- Entender `pacstrap`, `chroot`, `mkinitcpio`, y el rol de un bootloader.
- Verificar, con comandos, cómo quedó configurado cada aspecto en tu instalación real.
- Quedar preparado para poder reinstalar Arch desde cero si algún día lo necesitás (por ejemplo, en un laboratorio Break & Fix extremo o una máquina física).

---

## 1. CONCEPTO: por qué Arch se instala "a mano"

A diferencia de distribuciones como Ubuntu (que tienen un instalador gráfico que toma casi todas las decisiones por vos), Arch Linux te obliga a instalar el sistema **manualmente, comando por comando**, siguiendo la guía oficial (ArchWiki). Esto no es una limitación técnica — es una decisión filosófica: **si instalaste el sistema a mano, entendés exactamente qué tiene y por qué**, en vez de heredar un conjunto de paquetes y configuraciones que no elegiste ni entendés.

Este es exactamente el motivo por el que este curso usa Arch como laboratorio (recordá el README de la guía): "no se trata de memorizar comandos, se trata de entender el sistema".

---

## 2. POR QUÉ EXISTE cada etapa: el proceso de instalación completo

El proceso oficial de instalación de Arch sigue, en esencia, esta secuencia:

```
1. Arrancar desde el medio de instalación (ISO live)
2. Verificar conexión a internet
3. Particionar el disco
4. Formatear las particiones (crear filesystems)
5. Montar las particiones
6. Instalar el sistema base (pacstrap)
7. Generar fstab
8. Entrar al nuevo sistema (chroot)
9. Configurar zona horaria, localización, hostname
10. Configurar la red
11. Establecer contraseña de root
12. Instalar y configurar el bootloader
13. Salir, desmontar, reiniciar
```

Vamos a repasar las etapas más importantes, con su "por qué", y el comando para verificar cómo quedó resuelta en tu sistema.

### 2.1 Particionado del disco

**Por qué existe:** un disco físico es un espacio continuo de bytes; particionarlo significa dividirlo en secciones lógicas independientes, cada una con su propio filesystem, para separar responsabilidades (por ejemplo, separar `/boot` del resto permite que el bootloader encuentre el kernel de forma predecible incluso si el resto del sistema tiene problemas).

Herramientas típicas: `fdisk` (para MBR) o `gdisk`/`parted` (para GPT).

**Verificar en tu sistema:**
```bash
sudo fdisk -l /dev/sda
lsblk -f
```
Ya sabemos de módulos anteriores que tenés `sda1` (~1GB, `/boot`) y `sda2` (~49GB, `/`). Con `lsblk -f` vas a ver además el **tipo de filesystem** de cada partición (probablemente `ext4`).

### 2.2 Formatear particiones

**Por qué existe:** una partición vacía no tiene estructura — un filesystem (ext4, btrfs, xfs) es el "sistema de organización" que le permite al kernel saber dónde empieza y termina cada archivo, qué espacio está libre, permisos, etc.

```bash
mkfs.ext4 /dev/sda2    # ejemplo de cómo se formatea (NO lo ejecutes en tu sistema actual)
```

**Verificar en tu sistema:**
```bash
sudo blkid
```
Esto te muestra el UUID y tipo de filesystem de cada partición — información que también vive en tu `/etc/fstab` (siguiente punto).

### 2.3 pacstrap — instalar el sistema base

**Por qué existe:** `pacstrap` es un script que instala un conjunto mínimo de paquetes (`base`, el kernel, `linux-firmware`) directamente en las particiones recién montadas, formando el esqueleto del nuevo sistema — todavía **desde fuera** de él (estás corriendo esto desde el ISO live, no desde el sistema que estás instalando).

**Verificar en tu sistema** (ver qué paquetes del grupo base tenés):
```bash
pacman -Qg base 2>/dev/null || pacman -Q | grep -E "^(linux|base|linux-firmware) "
```

### 2.4 fstab — el mapa de montajes automáticos

**Por qué existe:** el kernel necesita saber, en cada arranque, qué partición montar en qué punto del árbol de directorios (`/`, `/boot`, etc.) sin que tengas que hacerlo a mano cada vez. `/etc/fstab` es ese mapa, generado automáticamente con `genfstab` durante la instalación.

**Verificar en tu sistema:**
```bash
cat /etc/fstab
```
Vas a ver líneas con el UUID de cada partición, su punto de montaje, tipo de filesystem y opciones. Esto es exactamente lo que en el Módulo de Break & Fix vas a corromper intencionalmente (incidente simulado #5: "/etc/fstab corrupto") para aprender a repararlo desde un modo de rescate.

### 2.5 chroot — entrar al sistema nuevo desde afuera

**Por qué existe:** `arch-chroot` te permite "teletransportarte" dentro del sistema recién instalado (que todavía no puede arrancar por sí solo) para terminar de configurarlo — como si ya hubieras reiniciado, pero sin haberlo hecho. Es una herramienta que vas a volver a usar en el Módulo 16 (Recuperación) para reparar un sistema que no arranca.

### 2.6 mkinitcpio — el initramfs

**Por qué existe:** cuando el kernel arranca, todavía no tiene cargados los drivers necesarios para acceder a discos complejos (RAID, LVM, cifrado). El **initramfs** es un miniassistente sistema de archivos temporal, cargado en RAM, que contiene justo los drivers y scripts necesarios para montar el disco real y continuar el arranque. `mkinitcpio` es la herramienta que genera ese initramfs en Arch.

**Verificar en tu sistema:**
```bash
ls -lh /boot/
```
Vas a ver archivos como `initramfs-linux.img` y `vmlinuz-linux` (el kernel comprimido). Estos dos archivos son los que el bootloader carga primero en cada arranque.

### 2.7 Bootloader (GRUB, en tu caso — porque sos BIOS legacy)

**Por qué existe:** ya lo vimos conceptualmente en el Módulo 00 — el firmware necesita un programa que le indique qué kernel cargar y con qué parámetros. En BIOS legacy, la opción estándar en Arch es **GRUB**.

**Verificar en tu sistema:**
```bash
cat /boot/grub/grub.cfg | head -n 30
sudo pacman -Q grub
```

---

## 3. CÓMO FUNCIONA: red y localización durante la instalación

Durante una instalación real, también se configura:

- **Zona horaria:** `ln -sf /usr/share/zoneinfo/Region/Ciudad /etc/localtime` y `hwclock --systohc`.
- **Localización (idioma/encoding):** se edita `/etc/locale.gen`, se corre `locale-gen`, y se define `LANG` en `/etc/locale.conf`.
- **Hostname:** el nombre de la máquina, en `/etc/hostname`.

**Verificar en tu sistema:**
```bash
timedatectl
cat /etc/locale.conf
cat /etc/hostname
```

---

## 4. EJEMPLO: recorrido completo de verificación

```bash
lsblk -f
sudo blkid
cat /etc/fstab
ls -lh /boot/
sudo pacman -Q grub
timedatectl
cat /etc/hostname
```

Este bloque, ejecutado en cualquier sistema Arch, te da un diagnóstico rápido de "cómo fue instalado" sin haber estado presente en la instalación original — una habilidad real de sysadmin: heredar un servidor de otra persona y entender su configuración leyendo el sistema, no preguntando.

---

## 5. PRÁCTICA

Ejecutá el bloque completo del punto 4 y contame:

1. ¿Qué tipo de filesystem usan `sda1` y `sda2` (según `lsblk -f`)?
2. ¿Qué UUID tiene cada partición en `/etc/fstab`, y coincide con lo que ves en `blkid`?
3. ¿Está instalado el paquete `grub`? ¿Qué versión?
4. ¿Qué hostname tiene tu máquina?
5. ¿Qué zona horaria te muestra `timedatectl`?

---

## 6. ERROR INTENCIONAL (versión segura, sin romper nada todavía)

Este módulo **no** incluye el Break & Fix real de `/etc/fstab` corrupto — ese laboratorio (incidente simulado #5 de la guía) requiere que primero domines el Módulo 16 (Recuperación) para poder revertirlo de forma segura con un medio de arranque live. Lo vamos a hacer ahí, con snapshot de VirtualBox tomado antes como red de seguridad.

Por ahora, hacé esto en modo **solo lectura**, sin modificar nada:

```bash
cat /etc/fstab
```

Preguntate: si borrara la línea que monta `/` (la raíz), ¿qué pasaría en el próximo arranque? (No lo hagas — respondelo conceptualmente, lo vas a comprobar de verdad más adelante).

---

## 7. DIAGNÓSTICO conceptual

Si la línea de `/` desapareciera de `fstab`, el kernel arrancaría pero **no sabría qué partición montar como raíz del sistema**, y el arranque fallaría o caería a un shell de emergencia (`initramfs emergency shell` o similar, dependiendo de la configuración). Este es exactamente el tipo de incidente que vas a resolver formalmente en el Módulo 16, usando un USB/ISO de Arch live, montando manualmente las particiones, haciendo `chroot`, y reparando el archivo.

---

## Checklist de cierre del módulo

- [ ] Entiendo las 13 etapas del proceso de instalación de Arch y el "por qué" de cada una.
- [ ] Sé diferenciar el rol de particionado, formateo, `pacstrap`, `fstab`, `chroot`, `mkinitcpio` y bootloader.
- [ ] Verifiqué en mi propio sistema: filesystem de particiones, UUIDs, paquete de bootloader, hostname, zona horaria.
- [ ] Entiendo conceptualmente qué pasaría si `/etc/fstab` se corrompiera (sin haberlo hecho todavía).

---

**Próximo módulo:** 07 — pacman y gestión de paquetes.
