# Módulo 09 — systemd

**Fase II — Arch Linux Core**

---

## Objetivos del módulo

- Entender qué es systemd y por qué reemplazó a los sistemas de inicio antiguos (SysVinit).
- Entender unidades (units): services, timers, targets, sockets.
- Gestionar servicios: iniciar, detener, habilitar, deshabilitar, ver estado.
- Leer logs de servicios con `journalctl`.
- Crear un servicio systemd propio y sencillo.

---

## 1. CONCEPTO: ¿qué es systemd?

Ya vimos en el Módulo 00 que el bootloader carga el kernel, y el kernel es lo primero que se ejecuta. Pero el kernel por sí solo no sabe qué servicios arrancar, en qué orden, ni cómo mantenerlos vivos. Esa responsabilidad se la delega a **PID 1** — el primer proceso de espacio de usuario que el kernel arranca. En Arch (y en la mayoría de distros modernas), ese proceso es **systemd**.

Ya lo viste con tus propios ojos en el Módulo 05: en `top`, `PID 1 = systemd`.

**systemd es mucho más que "el que arranca servicios":**
- Gestiona el arranque y apagado ordenado del sistema.
- Supervisa procesos y los reinicia si se caen (si así se configura).
- Gestiona logs centralizados (`journald`).
- Gestiona montajes de disco, dispositivos, red básica, timers (reemplazando cron en muchos casos).

---

## 2. POR QUÉ EXISTE: los problemas de SysVinit que systemd resuelve

### El sistema antiguo (SysVinit)

Antes de systemd, Linux arrancaba servicios con scripts de shell secuenciales, uno tras otro, en un orden fijo definido por números en el nombre del script (`S01red`, `S02sshd`, etc.). Esto tenía problemas serios:

1. **Arranque lento y secuencial** — cada servicio esperaba a que el anterior terminara, aunque no dependieran entre sí.
2. **Sin supervisión real** — si un servicio se caía, nadie lo notaba ni lo reiniciaba automáticamente.
3. **Dependencias frágiles** — el orden se definía a mano con números, propenso a errores.

### La solución de systemd

systemd define dependencias explícitas entre unidades y las arranca **en paralelo** cuando es posible, supervisa cada proceso, y puede reiniciarlo automáticamente si falla. Esto explica por qué los sistemas Linux modernos arrancan notablemente más rápido que hace 15 años.

**Nota histórica que vas a encontrar en la comunidad de Arch/Linux:** systemd es controvertido — algunos lo critican por ser demasiado abarcativo ("hace demasiadas cosas para ser solo un sistema de inicio"). Arch lo adoptó como estándar hace años, así que en este curso lo vas a usar como la herramienta principal para gestionar servicios, sin entrar en ese debate ideológico.

---

## 3. CÓMO FUNCIONA: unidades (units)

Todo lo que gestiona systemd es una **unidad**, definida en un archivo de configuración. Los tipos principales:

| Tipo | Extensión | Para qué sirve |
|---|---|---|
| Service | `.service` | Define un proceso/servicio (ej: `sshd.service`, `NetworkManager.service`) |
| Timer | `.timer` | Ejecuta algo en un horario/intervalo (reemplaza cron para muchos casos) |
| Target | `.target` | Agrupa unidades, marca un "estado" del sistema (ej: `multi-user.target` = sistema listo en modo texto) |
| Socket | `.socket` | Activa un servicio cuando llega tráfico a un socket/puerto (activación bajo demanda) |
| Mount | `.mount` | Define un punto de montaje gestionado por systemd |

Las unidades viven principalmente en `/usr/lib/systemd/system/` (las que vienen con paquetes) y `/etc/systemd/system/` (las que vos personalizás o creás — tienen prioridad sobre las anteriores).

---

## 4. HERRAMIENTA: `systemctl` — gestión de servicios

```bash
systemctl status sshd              # ver el estado de un servicio (corriendo, detenido, con errores)
sudo systemctl start sshd           # iniciarlo ahora
sudo systemctl stop sshd            # detenerlo ahora
sudo systemctl restart sshd         # reiniciarlo
sudo systemctl enable sshd          # que arranque automáticamente en cada boot
sudo systemctl disable sshd         # que NO arranque automáticamente
sudo systemctl enable --now sshd    # habilitar Y arrancar en un solo comando (muy usado)

systemctl list-units --type=service           # todos los servicios cargados
systemctl list-units --type=service --state=running   # solo los que están corriendo
systemctl list-unit-files --state=enabled       # todos los que arrancan automáticamente en boot

systemctl is-active sshd     # solo te dice: active / inactive
systemctl is-enabled sshd     # solo te dice: enabled / disabled
```

**Diferencia clave que mucha gente confunde:** `start`/`stop` actúan **ahora mismo**; `enable`/`disable` deciden si arranca **en el próximo boot**. Un servicio puede estar `enabled` pero no `active` (está configurado para arrancar, pero todavía no arrancó o se cayó), o `active` sin estar `enabled` (lo prendiste a mano, pero no sobrevive a un reinicio).

---

## 5. CÓMO FUNCIONA: `journalctl` — logs centralizados

systemd centraliza los logs de (casi) todo el sistema en el **journal**, un formato binario indexado (no archivos de texto plano como en sistemas antiguos), que ya viste físicamente en `/var/log/journal` en el Módulo 02.

```bash
journalctl                       # todo el log completo, desde el boot más antiguo guardado
journalctl -u sshd                # logs de un servicio específico
journalctl -b                      # logs solo del boot actual
journalctl -b -1                   # logs del boot ANTERIOR (muy útil tras un crash)
journalctl -f                       # seguir en vivo (como "tail -f")
journalctl -p err                   # solo mensajes de nivel error o más grave
journalctl --since "10 min ago"     # filtrar por tiempo
journalctl --disk-usage              # cuánto espacio ocupa el journal
```

Este comando (`journalctl -u <servicio>`) va a ser tu primera herramienta de diagnóstico cada vez que un servicio falle — mucho antes de tocar cualquier archivo de configuración.

---

## 6. EJEMPLO: crear un servicio systemd propio

Vamos a crear un servicio mínimo que escriba un mensaje en el journal cada vez que corre.

```bash
sudo tee /etc/systemd/system/saludo.service << 'EOF'
[Unit]
Description=Servicio de saludo de prueba

[Service]
Type=oneshot
ExecStart=/usr/bin/echo "Hola desde systemd, corrido por fabian"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload      # avisarle a systemd que hay una unidad nueva/modificada
sudo systemctl start saludo.service
journalctl -u saludo.service
```

Cada vez que modifiques o crees un archivo `.service` a mano, **siempre** hay que correr `sudo systemctl daemon-reload` para que systemd relea la configuración — es un error muy común olvidarlo y preguntarse por qué "el cambio no aplicó".

---

## 7. PRÁCTICA

1. `systemctl list-units --type=service --state=running` — ¿qué servicios están corriendo ahora? Identificá al menos 3 (por ejemplo `NetworkManager`, `sshd` si está instalado, `dbus`).
2. `systemctl status NetworkManager` — leé el estado completo: ¿está `active (running)`? ¿Hace cuánto arrancó?
3. Creá el servicio `saludo.service` del ejemplo, arrancalo, y confirmá el mensaje con `journalctl -u saludo.service`.
4. `systemctl is-enabled saludo.service` — ¿qué te dice? (Pista: no lo habilitamos con `enable`, solo lo arrancamos una vez con `start`).
5. `journalctl -b | wc -l` — ¿cuántas líneas de log tiene tu boot actual?

---

## 8. ERROR INTENCIONAL (Break & Fix — incidente simulado #4 de la guía)

Vamos a simular el incidente "Servicio systemd caído":

```bash
sudo tee /etc/systemd/system/roto.service << 'EOF'
[Unit]
Description=Servicio con un error intencional

[Service]
Type=simple
ExecStart=/usr/bin/comando-que-no-existe

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start roto.service
systemctl status roto.service
```

---

## 9. DIAGNÓSTICO

Metodología de la guía: **SÍNTOMA → OBSERVACIÓN → MÉTRICA → LOG → PROCESO → CAUSA RAÍZ → SOLUCIÓN → VALIDACIÓN**

1. **Síntoma:** `systemctl status roto.service` va a mostrar `failed` (rojo) en vez de `active (running)`.
2. **Observación:** el estado indica algo como `Main PID: ... (code=exited, status=203/EXEC)`.
3. **Log:** `journalctl -u roto.service` — ahí vas a ver el detalle: no pudo ejecutar el binario porque no existe.
4. **Causa raíz:** el `ExecStart` apunta a un comando/ruta que no existe en el sistema.

---

## 10. SOLUCIÓN

```bash
sudo systemctl stop roto.service
sudo nano /etc/systemd/system/roto.service   # corregir ExecStart a algo real, ej: /usr/bin/echo "arreglado"
sudo systemctl daemon-reload
sudo systemctl restart roto.service
systemctl status roto.service                 # confirmar "active"
```

**Validación:** `systemctl status` en verde/active, sin errores en `journalctl -u roto.service --since "1 min ago"`.

**Limpieza (rollback completo):**
```bash
sudo systemctl disable --now roto.service saludo.service
sudo rm /etc/systemd/system/roto.service /etc/systemd/system/saludo.service
sudo systemctl daemon-reload
```

---

## Checklist de cierre del módulo

- [ ] Entiendo por qué systemd reemplazó a SysVinit y qué problema resuelve.
- [ ] Sé diferenciar `start`/`stop` de `enable`/`disable`.
- [ ] Sé leer logs con `journalctl -u`, `journalctl -b`, `journalctl -f`.
- [ ] Creé un servicio systemd propio desde cero.
- [ ] Completé el laboratorio Break & Fix de servicio caído (incidente simulado #4 de la guía) y lo reparé.

---

**Próximo módulo:** 10 — Proceso de arranque (boot).
