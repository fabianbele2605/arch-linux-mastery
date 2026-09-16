# Arch Linux Master Course

**De Cero a Ingeniero de Sistemas Linux**

Curso de formación profesional que lleva a un estudiante desde cero conocimiento de Linux hasta un nivel de administrador de sistemas / ingeniero DevOps / ingeniero de seguridad, usando **Arch Linux** como laboratorio principal de aprendizaje.

No es un tutorial de comandos. Cada módulo enseña primero **por qué existe** y **cómo funciona** algo, antes de mostrar **cómo se usa** — con laboratorios prácticos, errores intencionales ("Break & Fix") y ejercicios de diagnóstico real.

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

### 🔄 Fase III — Networking & Security
- [x] [12 — Networking](12-networking/12-networking.md)
- [x] [13 — SSH](13-ssh/13-ssh.md)
- [x] [14 — Firewall y hardening](14-firewall-security/14-firewall-y-hardening.md)
- [x] [15 — Logs y troubleshooting](15-logs-troubleshooting/15-logs-y-troubleshooting.md)
- [ ] 16 — Recuperación de sistemas rotos

### ⬜ Fase IV — Development & Automation
- [ ] 17 — Bash profesional
- [ ] 18 — Git
- [ ] 19 — Python para sysadmin
- [ ] 20 — C para entender Linux
- [ ] 21 — Rust para sistemas

### ⬜ Fase V — Infrastructure & Advanced Systems
- [ ] 22 — Kernel Linux
- [ ] 23 — Virtualización (QEMU/KVM/libvirt)
- [ ] 24 — Contenedores (Docker/Podman)
- [ ] 25 — Servidores web (Nginx/Caddy/TLS)
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
- [ ] #5 — `/etc/fstab` corrupto
- [x] #6 — Bootloader dañado (Módulo 10)
- [ ] #7 — initramfs corrupto
- [x] #8 — Firewall mal configurado (Módulo 14)
- [x] #9 — Disco lleno / filesystem inconsistente (Módulo 15)
- [ ] #10 — Conflicto de gestión de paquetes

---

## Estructura del repositorio

```
arch-linux-mastery/
├── docs/guia.md              ← guía completa del curso
├── 00-fundamentals/ ... 30-osdev/    ← un módulo por carpeta
├── labs/break-and-fix/        ← laboratorios de incidentes simulados
├── projects/                    ← proyectos progresivos del curso
├── cheatsheets/                  ← referencias rápidas
└── troubleshooting/                ← guías de diagnóstico
```

## Entorno

- Arch Linux instalado en VirtualBox (BIOS legacy, disco `sda` con `/boot` en `sda1` y `/` en `sda2`)
- Cada laboratorio que modifica bootloader/initramfs/disco se practica con snapshot de VirtualBox tomado de antemano
