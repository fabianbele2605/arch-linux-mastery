# ARCH LINUX MASTER COURSE
## De Cero a Ingeniero de Sistemas Linux

---

## README

Este es un programa de formación profesional diseñado para llevar a un estudiante desde **cero conocimiento de Linux** hasta un nivel de **administrador de sistemas / ingeniero DevOps / ingeniero de seguridad**, utilizando **Arch Linux** como laboratorio principal de aprendizaje.

No es un tutorial de comandos. Es un curso estructurado en fases, módulos, lecciones, laboratorios y proyectos, donde cada tema se enseña respondiendo primero **por qué existe** y **cómo funciona**, antes de mostrar **cómo se usa**.

El curso asume que el estudiante ya tiene Arch Linux instalado (en una máquina virtual) y acceso a una terminal.

**Filosofía central:**

> No se trata de memorizar comandos. Se trata de entender el sistema lo suficientemente bien como para instalarlo, administrarlo, diagnosticarlo, asegurarlo, automatizarlo y programar sobre él.

---

## CÓMO ESTUDIAR ESTE CURSO

Cada módulo sigue esta secuencia de aprendizaje:

```
CONCEPTO → POR QUÉ EXISTE → CÓMO FUNCIONA → HERRAMIENTA →
EJEMPLO → PRÁCTICA → ERROR INTENCIONAL → DIAGNÓSTICO →
SOLUCIÓN → RETO
```

Reglas de progresión:

- No se introduce una herramienta antes de que el concepto que la justifica haya sido enseñado.
- No se enseña Kubernetes antes de dominar Linux, redes, systemd, SSH y contenedores.
- No se enseña Rust avanzado antes de entender C, memoria, procesos y syscalls.
- Cada fase se cierra con una evaluación antes de continuar a la siguiente.

---

## PRERREQUISITOS

- Arch Linux instalado en una máquina virtual (VirtualBox, QEMU/KVM o similar).
- Acceso a terminal con usuario normal y privilegios `sudo`.
- Conexión a internet dentro de la VM.
- Disposición para romper cosas intencionalmente y repararlas (los laboratorios "Break & Fix" son obligatorios, no opcionales).
- Ninguna experiencia previa en Linux es necesaria. Ninguna experiencia de programación es necesaria para las fases iniciales.

---

## VISIÓN GENERAL DEL RECORRIDO

```
Fundamentos de computación
        ↓
Linux desde cero (terminal, filesystem, texto)
        ↓
Usuarios, permisos y procesos
        ↓
Instalación profesional de Arch
        ↓
Gestión de paquetes (pacman + AUR)
        ↓
systemd y arranque del sistema
        ↓
Almacenamiento avanzado
        ↓
Redes y SSH
        ↓
Firewall y seguridad
        ↓
Logs y troubleshooting
        ↓
Recuperación de sistemas rotos
        ↓
Bash profesional
        ↓
Git
        ↓
Python para administración de sistemas
        ↓
C para entender Linux a bajo nivel
        ↓
Rust para programación de sistemas
        ↓
Kernel Linux
        ↓
Virtualización
        ↓
Contenedores
        ↓
Servidores web y bases de datos
        ↓
DevOps (CI/CD, Ansible, IaC)
        ↓
Observabilidad (logs, métricas, alertas)
        ↓
Ciberseguridad defensiva
        ↓
OS Development (fundamentos)
        ↓
Proyecto final de infraestructura
```

---

## FASES DEL CURSO

El curso se organiza en **6 grandes fases**, cada una compuesta por varios módulos.

### FASE 0 — Fundamentos
Conceptos de hardware, firmware y arranque necesarios antes de tocar Linux.

### FASE I — Linux Fundamentals
Terminal, filesystem, procesamiento de texto, usuarios, permisos, procesos.

### FASE II — Arch Linux Core
Instalación manual, pacman, AUR, systemd, boot, almacenamiento.

### FASE III — Networking & Security
Redes, SSH, firewall, seguridad, logs, troubleshooting, recuperación de desastres.

### FASE IV — Development & Automation
Bash, Git, Python, C, Rust — la ruta de programación orientada a sistemas.

### FASE V — Infrastructure & Advanced Systems
Kernel, virtualización, contenedores, servidores, bases de datos, DevOps, observabilidad, seguridad ofensiva/defensiva y fundamentos de OSDev.

---

## MAPA COMPLETO DE MÓDULOS

| Fase | Módulo | Nombre |
|---|---|---|
| 0 | 00 | Fundamentos de computación |
| I | 01 | Terminal y shell |
| I | 02 | Filesystem de Linux |
| I | 03 | Texto y procesamiento (pipes, redirecciones) |
| I | 04 | Usuarios y permisos |
| I | 05 | Procesos |
| II | 06 | Instalación profesional de Arch Linux |
| II | 07 | pacman y gestión de paquetes |
| II | 08 | AUR y PKGBUILD |
| II | 09 | systemd |
| II | 10 | Proceso de arranque (boot) |
| II | 11 | Almacenamiento (particiones, filesystems, LVM, RAID, LUKS) |
| III | 12 | Networking |
| III | 13 | SSH |
| III | 14 | Firewall y hardening |
| III | 15 | Logs y troubleshooting |
| III | 16 | Recuperación de sistemas rotos |
| IV | 17 | Bash profesional |
| IV | 18 | Git |
| IV | 19 | Python para sysadmin |
| IV | 20 | C para entender Linux |
| IV | 21 | Rust para sistemas |
| V | 22 | Kernel Linux |
| V | 23 | Virtualización (QEMU/KVM/libvirt) |
| V | 24 | Contenedores (Docker/Podman) |
| V | 25 | Servidores web (Nginx/Caddy/TLS) |
| V | 26 | Bases de datos (PostgreSQL) |
| V | 27 | DevOps (CI/CD, Ansible, IaC) |
| V | 28 | Observabilidad (Prometheus/Grafana) |
| V | 29 | Ciberseguridad defensiva |
| V | 30 | Fundamentos de OS Development |

---

## METODOLOGÍA DE LABORATORIOS

Cada laboratorio del curso sigue esta plantilla:

```
Objetivo
Requisitos
Preparación
Concepto aplicado
Procedimiento
Validación del resultado
Errores comunes
Troubleshooting
Cómo revertir (rollback)
Reto adicional
Preguntas de reflexión
```

### Laboratorios "Break & Fix" (obligatorios)

A lo largo del curso, el estudiante romperá intencionalmente su propio sistema para aprender a diagnosticarlo y repararlo. Lista de incidentes simulados:

1. Resolución DNS rota
2. Acceso SSH bloqueado
3. Permisos de archivos incorrectos
4. Servicio systemd caído
5. `/etc/fstab` corrupto (el sistema no monta)
6. Bootloader dañado
7. initramfs corrupto
8. Firewall mal configurado (bloqueo total)
9. Disco lleno / filesystem inconsistente
10. Conflicto de gestión de paquetes

Metodología de diagnóstico aplicada en todos los casos:

```
SÍNTOMA → OBSERVACIÓN → MÉTRICA → LOG →
PROCESO → CAUSA RAÍZ → SOLUCIÓN → VALIDACIÓN
```

---

## SISTEMA DE EVALUACIÓN

Cada fase cierra con:

- **Preguntas conceptuales** — verifican comprensión, no memorización.
- **Ejercicios prácticos** — aplicación directa en terminal.
- **Ejercicio de troubleshooting** — un incidente simulado a resolver sin guía paso a paso.
- **Mini-proyecto** — integra varios módulos de la fase.

Niveles de dificultad presentes en cada módulo:

| Nivel | Tipo de ejercicio |
|---|---|
| Básico | Preguntas de comprensión del concepto |
| Intermedio | Ejercicios prácticos guiados |
| Avanzado | Problemas abiertos sin solución inmediata |
| Experto | Incidentes simulados de producción |

Al final del curso se realiza un **examen final integrador** que cubre las 6 fases.

---

## PROYECTOS DEL CURSO

Los proyectos son progresivos: cada uno depende de conocimientos de proyectos anteriores.

| # | Proyecto | Fase asociada |
|---|---|---|
| 1 | Laboratorio de línea de comandos | I |
| 2 | Instalación manual completa de Arch | II |
| 3 | Servidor accesible únicamente por SSH | III |
| 4 | Servidor endurecido con firewall | III |
| 5 | Sistema de backups automatizado | III/IV |
| 6 | Monitor de sistema en Bash | IV |
| 7 | Analizador de logs en Python | IV |
| 8 | Servicio systemd personalizado (con timer) | II |
| 9 | Servidor web con reverse proxy y TLS | V |
| 10 | Aplicación conectada a PostgreSQL | V |
| 11 | Servidor de contenedores con Docker | V |
| 12 | Laboratorio virtualizado multi-VM | V |
| 13 | Sistema con observabilidad (métricas + alertas) | V |
| 14 | Kernel personalizado compilado | V |
| 15 | **Proyecto final de infraestructura completa** | Final |

### Proyecto final — Arquitectura objetivo

```
                       INTERNET
                          |
                 ┌────────────────┐
                 │  ARCH SERVER   │
                 └───────┬────────┘
                         |
             ┌───────────┼───────────┐
             ↓           ↓           ↓
           SSH        Firewall    Monitoring
                         |
                         ↓
                  Reverse Proxy (TLS)
                         |
              ┌──────────┴──────────┐
              ↓                     ↓
         Aplicación A          Aplicación B
              |                     |
              └──────────┬──────────┘
                         ↓
                     PostgreSQL
                         |
                         ↓
                      Backups
```

Debe incluir: usuarios administrados, acceso SSH endurecido, firewall activo, TLS válido, servidor web, aplicación desplegada, base de datos, backups automatizados, monitoreo, gestión de logs, servicios systemd, contenedores Docker, documentación completa y plan de recuperación ante desastres.

---

## ESTRUCTURA DE ARCHIVOS DEL CURSO

```
arch-linux-course/
│
├── README.md
├── ROADMAP.md
│
├── 00-fundamentals/
├── 01-terminal/
├── 02-filesystem/
├── 03-text-processing/
├── 04-users-permissions/
├── 05-processes/
├── 06-arch-installation/
├── 07-pacman/
├── 08-aur-pkgbuild/
├── 09-systemd/
├── 10-boot/
├── 11-storage/
├── 12-networking/
├── 13-ssh/
├── 14-firewall-security/
├── 15-logs-troubleshooting/
├── 16-recovery/
├── 17-bash/
├── 18-git/
├── 19-python/
├── 20-c/
├── 21-rust/
├── 22-kernel/
├── 23-virtualization/
├── 24-containers/
├── 25-web-servers/
├── 26-databases/
├── 27-devops/
├── 28-observability/
├── 29-security-lab/
├── 30-osdev/
│
├── labs/
│   └── break-and-fix/
├── projects/
├── cheatsheets/
└── troubleshooting/
```

Cada carpeta de módulo contendrá, cuando se desarrolle en detalle: objetivos, conceptos, arquitectura, herramientas, ejemplos, laboratorio, ejercicio, error intencional, troubleshooting, reto, proyecto, checklist y preguntas de evaluación.

---

## FUENTES DE REFERENCIA OFICIALES

Dado que Arch Linux es una distribución *rolling release*, los procedimientos cambian con el tiempo. Este curso prioriza siempre:

1. **ArchWiki** (fuente principal y más actualizada)
2. Documentación oficial de Arch Linux
3. Documentación oficial de cada proyecto (systemd, pacman, etc.)
4. Páginas `man`
5. Documentación oficial del kernel Linux

Cuando un procedimiento dependa de información que pueda cambiar (versiones de bootloader, nombres de paquetes, sintaxis de herramientas), el curso lo señalará explícitamente para que se verifique contra la documentación vigente antes de ejecutarlo.

---

## CRONOGRAMA RECOMENDADO

Ritmo sugerido para un estudiante dedicando estudio constante (ajustable según disponibilidad):

| Fase | Contenido | Duración estimada |
|---|---|---|
| 0 | Fundamentos de computación | 1 semana |
| I | Linux Fundamentals (terminal, filesystem, texto, permisos, procesos) | 3–4 semanas |
| II | Arch Linux Core (instalación, pacman, AUR, systemd, boot, storage) | 4–6 semanas |
| III | Networking & Security (redes, SSH, firewall, logs, recuperación) | 4–5 semanas |
| IV | Development & Automation (Bash, Git, Python, C, Rust) | 6–8 semanas |
| V | Infrastructure & Advanced Systems (kernel, virtualización, contenedores, servidores, DevOps, OSDev) | 8–12 semanas |

**Duración total estimada: entre 6 y 9 meses**, dependiendo del ritmo de estudio y la profundidad con que se aborden los proyectos.

---

## PRÓXIMO PASO

Con este mapa como referencia, el curso comienza a desarrollarse módulo por módulo, empezando por la **Fase 0 — Fundamentos de computación**, siguiendo siempre la secuencia:

```
CONCEPTO → POR QUÉ EXISTE → CÓMO FUNCIONA →
HERRAMIENTA → EJEMPLO → PRÁCTICA →
ERROR INTENCIONAL → DIAGNÓSTICO → SOLUCIÓN → RETO
```

Cada módulo se entregará de forma completa y sin resumir artificialmente contenido extenso; si un tema es demasiado amplio, se dividirá en varias lecciones dentro del mismo módulo.