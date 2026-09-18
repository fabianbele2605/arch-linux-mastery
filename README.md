# Arch Linux Master Course

**De Cero a Ingeniero de Sistemas Linux**

![Progreso](https://img.shields.io/badge/progreso-25%2F30%20m%C3%B3dulos-brightgreen)
![Break & Fix](https://img.shields.io/badge/break%20%26%20fix-8%2F10%20incidentes-orange)
![Fases](https://img.shields.io/badge/fases-4%2F6%20completas-blue)
![Método](https://img.shields.io/badge/m%C3%A9todo-hands--on%20en%20Arch%20Linux%20real-informational)

---

## 🎯 De qué se trata esto

Un curso propio, de 30 módulos, para pasar de cero conocimiento de Linux a nivel de administrador de sistemas / DevOps / seguridad — usando **Arch Linux real en una VM** como único laboratorio, no un simulador ni una serie de videos.

**No es "seguir instrucciones".** Cada módulo se ejecuta de verdad en mi propia terminal, y cada resultado (bueno o roto) queda documentado con evidencia real: capturas de pantalla con descripción de qué pasó, qué comando lo causó, y cómo se diagnosticó.

Lo uso como caso de estudio de **aprender una habilidad técnica profunda con un tutor de IA**: la IA diseña el currículum, explica el "por qué" antes del "cómo", y me hace ejecutar todo yo mismo en mi propia VM — corrigiendo errores reales de tipeo, de red, de configuración, tal como pasarían en un trabajo real.

### Algunos hallazgos reales del camino (no simulados)

- 🔥 Un firewall mal configurado en el **Módulo 14** rompió silenciosamente todo el tráfico de Docker **10 módulos después**, en el Módulo 24 — tuve que diagnosticarlo yo mismo, en capas, hasta encontrar la causa raíz.
- 🕵️ Descubrí en pleno debugging de certificados que la red wifi que estaba usando intercepta tráfico HTTPS con un firewall corporativo (Fortinet) — un hallazgo de seguridad real, no parte del plan.
- 🔧 Escribí, compilé y cargué mi propio módulo de kernel en C, con bugs reales de sintaxis que tuve que resolver con `gdb` y lectura de logs del kernel.
- 🐘 Encontré y aproveché para auditar un stack completo de observabilidad (Grafana, Prometheus, Loki) que tenía olvidado en Docker de un proyecto anterior.

📖 **[Ver la guía completa del curso](docs/guia.md)** — fases, metodología, evaluación, proyectos y cronograma.

---

## Progreso

### ✅ Fase 0 — Fundamentos
- [x] [00 — Fundamentos de computación](00-fundamentals/00-fundamentos-de-computacion.md)

### ✅ Fase I — Linux Fundamentals
- [x] [01 — Terminal y shell](01-terminal/01-terminal-y-shell.md)
- [x] [02 — Filesystem de Linux](02-filesystem/02-filesystem-de-linux.md)
- [x] [03 — Texto y procesamiento](03-text-processing/03-texto-y-procesamiento.md)
- [x] [04 — Usuarios y permisos](04-users-permissions/04-usuarios-y-permisos.md)
- [x] [05 — Procesos](05-processes/05-procesos.md)

### ✅ Fase II — Arch Linux Core
- [x] [06 — Instalación profesional de Arch Linux](06-arch-installation/06-instalacion-profesional-de-arch.md)
- [x] [07 — pacman y gestión de paquetes](07-pacman/07-pacman-y-gestion-de-paquetes.md)
- [x] [08 — AUR y PKGBUILD](08-aur-pkgbuild/08-aur-y-pkgbuild.md)
- [x] [09 — systemd](09-systemd/09-systemd.md)
- [x] [10 — Proceso de arranque (boot)](10-boot/10-proceso-de-arranque.md)
- [x] [11 — Almacenamiento (LVM, RAID, LUKS)](11-storage/11-almacenamiento.md)

### ✅ Fase III — Networking & Security
- [x] [12 — Networking](12-networking/12-networking.md)
- [x] [13 — SSH](13-ssh/13-ssh.md)
- [x] [14 — Firewall y hardening](14-firewall-security/14-firewall-y-hardening.md)
- [x] [15 — Logs y troubleshooting](15-logs-troubleshooting/15-logs-y-troubleshooting.md)
- [x] [16 — Recuperación de sistemas rotos](16-recovery/16-recuperacion-de-sistemas-rotos.md)

### ✅ Fase IV — Development & Automation
- [x] [17 — Bash profesional](17-bash/17-bash-profesional.md)
- [x] [18 — Git](18-git/18-git.md)
- [x] [19 — Python para sysadmin](19-python/19-python-para-sysadmin.md)
- [x] [20 — C para entender Linux](20-c/20-c-para-entender-linux.md)
- [x] [21 — Rust para sistemas](21-rust/21-rust-para-sistemas.md)

### 🔄 Fase V — Infrastructure & Advanced Systems
- [x] [22 — Kernel Linux](22-kernel/22-kernel-linux.md)
- [x] [23 — Virtualización (QEMU/KVM/libvirt)](23-virtualization/23-virtualizacion.md)
- [x] [24 — Contenedores (Docker/Podman)](24-containers/24-contenedores.md)
- [x] [25 — Servidores web (Nginx/Caddy/TLS)](25-web-servers/25-servidores-web.md)
- [ ] 26 — Bases de datos (PostgreSQL)
- [ ] 27 — DevOps (CI/CD, Ansible, IaC)
- [ ] 28 — Observabilidad (Prometheus/Grafana)
- [ ] 29 — Ciberseguridad defensiva
- [ ] 30 — Fundamentos de OS Development

---

## Laboratorios Break & Fix completados

Incidentes simulados de la metodología SÍNTOMA → OBSERVACIÓN → LOG → CAUSA RAÍZ → SOLUCIÓN → VALIDACIÓN:

- [x] #1 — Resolución DNS rota (Módulo 12)
- [x] #2 — Acceso SSH bloqueado (Módulo 13)
- [ ] #3 — Permisos de archivos incorrectos
- [x] #4 — Servicio systemd caído (Módulo 09)
- [x] #5 — `/etc/fstab` corrupto (Módulo 16)
- [x] #6 — Bootloader dañado (Módulo 10)
- [x] #7 — initramfs corrupto (Módulo 16)
- [x] #8 — Firewall mal configurado (Módulo 14)
- [x] #9 — Disco lleno / filesystem inconsistente (Módulo 15)
- [ ] #10 — Conflicto de gestión de paquetes

---

## Cómo está documentado cada módulo

Cada carpeta de módulo tiene su archivo `.md` con teoría + práctica, y una carpeta `evidencias/` con capturas reales de mi propia VM, cada una con una descripción de qué comando se corrió y qué pasó — incluyendo los errores reales (typos, problemas de red, configuraciones mal hechas) y cómo se diagnosticaron y resolvieron.

## Estructura del repositorio

```
arch-linux-mastery/
├── docs/guia.md              ← guía completa del curso
├── 00-fundamentals/ ... 30-osdev/    ← un módulo por carpeta, con su evidencias/
├── labs/break-and-fix/        ← laboratorios de incidentes simulados
├── projects/                    ← proyectos progresivos del curso
├── cheatsheets/                  ← referencias rápidas
└── troubleshooting/                ← guías de diagnóstico
```

## Entorno

- Arch Linux instalado en VirtualBox (BIOS legacy, disco `sda` con `/boot` en `sda1` y `/` en `sda2`)
- Cada laboratorio que modifica bootloader/initramfs/disco se practica con snapshot de VirtualBox tomado de antemano
