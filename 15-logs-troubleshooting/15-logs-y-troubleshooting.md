# Módulo 15 — Logs y troubleshooting

**Fase III — Networking & Security**

---

## Objetivos del módulo

- Profundizar `journalctl` más allá de lo visto en el Módulo 09 (filtros avanzados, prioridades, exportación).
- Entender la diferencia entre el journal de systemd y el syslog tradicional.
- Entender rotación y límites de tamaño de logs (`journald.conf`, `logrotate`).
- Usar `dmesg` para diagnóstico de kernel/hardware.
- Consolidar la metodología de troubleshooting usada en todo el curso.
- Resolver el incidente simulado #9 de la guía: "Disco lleno / filesystem inconsistente".

---

## 1. CONCEPTO: por qué los logs son la fuente de verdad

A lo largo del curso, cada vez que algo falló (DNS, SSH, un servicio systemd, GRUB), la secuencia de diagnóstico terminó en el mismo lugar: **revisar los logs**. Esto no es casualidad — los logs son el único registro objetivo de **qué pasó realmente**, en el orden en que pasó, sin depender de tu memoria o suposiciones.

**Por qué importa dominar esto:** en un incidente real de producción, bajo presión, la diferencia entre un administrador junior y uno experimentado casi siempre es la velocidad y precisión con la que sabe **dónde mirar** y **cómo filtrar el ruido** para encontrar la línea que importa entre miles.

---

## 2. POR QUÉ EXISTE: journal binario vs. syslog de texto plano

### El sistema antiguo (syslog)

Tradicionalmente, Linux escribía logs como **texto plano** en archivos separados por servicio/categoría (`/var/log/messages`, `/var/log/auth.log`, etc.), gestionados por un daemon como `rsyslogd`.

### El journal de systemd

systemd centraliza todo en un **formato binario indexado** (ya lo viste físicamente en `/var/log/journal` en el Módulo 02). Ventajas:
- **Indexado y buscable** eficientemente (por servicio, por tiempo, por prioridad) sin tener que hacer `grep` sobre archivos gigantes.
- **Metadata estructurada** — cada entrada sabe automáticamente qué proceso, PID, usuario y unidad systemd la generó.
- **Persistencia configurable** — podés decidir si sobrevive a reinicios o no.

**Nota:** Arch puede tener ambos sistemas conviviendo (algunos programas todavía escriben a `/var/log/*.log` en texto plano), pero el journal es el estándar recomendado y el que vas a usar como primera herramienta.

---

## 3. CÓMO FUNCIONA: `journalctl` avanzado

Ya viste lo básico en el Módulo 09. Ahora profundicemos:

```bash
journalctl -p err -b                    # solo errores (o más grave) del boot actual
journalctl -p warning..err               # rango de prioridades (warning hasta error)
journalctl _PID=1234                      # filtrar por PID específico
journalctl _UID=1000                       # filtrar por usuario (UID)
journalctl -u sshd -u nftables             # múltiples unidades a la vez
journalctl --since "2026-09-15 20:00" --until "2026-09-15 23:00"   # rango de tiempo exacto
journalctl -o json-pretty | head -n 30       # salida en JSON (útil para procesar con scripts, Módulo 19)
journalctl -k                                  # solo mensajes del kernel (equivalente a dmesg, pero desde el journal)
```

### Niveles de prioridad (de más a menos grave)

```
0 emerg    1 alert    2 crit    3 err    4 warning    5 notice    6 info    7 debug
```

Cuando algo falla, `journalctl -p err -b` es casi siempre tu primer comando — filtra directamente el ruido de nivel `info`/`debug` que no aporta al diagnóstico.

---

## 4. CÓMO FUNCIONA: tamaño y rotación de logs

El journal puede crecer indefinidamente si no se limita. Se configura en `/etc/systemd/journald.conf`:

```bash
cat /etc/systemd/journald.conf | grep -v "^#"
journalctl --disk-usage              # cuánto espacio ocupa ahora mismo
```

Opciones clave (normalmente comentadas por defecto, usando límites automáticos razonables):
```
SystemMaxUse=500M       # tope máximo de espacio en disco para el journal
MaxRetentionSec=1month   # cuánto tiempo conservar logs
```

```bash
sudo journalctl --vacuum-size=200M    # reducir el journal a un tamaño máximo específico, ahora
sudo journalctl --vacuum-time=2weeks   # eliminar todo lo más viejo que 2 semanas
```

Para logs en texto plano tradicionales (los pocos que todavía existen en `/var/log/*.log`), la rotación la maneja `logrotate`, configurado en `/etc/logrotate.conf` y `/etc/logrotate.d/`.

---

## 5. HERRAMIENTA: `dmesg` — el buffer de mensajes del kernel

```bash
dmesg                    # todo el buffer de mensajes del kernel desde el boot
dmesg -H                  # con timestamps legibles ("human")
dmesg -l err,crit          # filtrar por nivel de severidad
dmesg | grep -i usb         # ej: diagnosticar un dispositivo USB que no se detecta
dmesg -w                     # seguir en vivo (como tail -f), útil para ver qué pasa al conectar hardware
```

`dmesg` es tu herramienta específica para problemas de **hardware y drivers** — cosas que ocurren antes o fuera del alcance normal de systemd (detección de discos, USB, memoria, errores de controlador).

---

## 6. CONSOLIDACIÓN: la metodología de troubleshooting del curso

A esta altura ya aplicaste esta secuencia varias veces (Módulos 09, 10, 12, 13, 14). Formalicémosla:

```
1. SÍNTOMA        → ¿qué está fallando, exactamente, desde la perspectiva del usuario/sistema?
2. OBSERVACIÓN    → ¿qué comandos de estado confirman el síntoma? (systemctl status, ping, etc.)
3. MÉTRICA        → ¿hay números que acoten el problema? (uso de disco, CPU, memoria, latencia)
4. LOG             → ¿qué dicen journalctl/dmesg sobre el momento exacto de la falla?
5. PROCESO          → ¿qué proceso/servicio específico está involucrado?
6. CAUSA RAÍZ        → ¿por qué está pasando esto, en términos concretos y verificables?
7. SOLUCIÓN           → el cambio mínimo necesario para resolver la causa raíz (no solo el síntoma)
8. VALIDACIÓN          → confirmar con evidencia (no solo "parece que anda") que quedó resuelto
```

**Por qué el orden importa:** saltarse pasos (por ejemplo, ir directo a "solución" sin confirmar la causa raíz) es la forma más común de "arreglar" un síntoma sin resolver el problema real — y de que vuelva a fallar días después.

---

## 7. EJEMPLO

```bash
journalctl -p err -b --no-pager | tail -n 30
dmesg -H -l err,crit
journalctl --disk-usage
df -h
```

---

## 8. PRÁCTICA

1. `journalctl -p err -b` — ¿tenés algún error registrado en el boot actual? Si no hay nada, es buena señal.
2. `journalctl -u sshd -u nftables --since "1 hour ago"` — revisá la actividad reciente de ambos servicios.
3. `dmesg -H | tail -n 20` — ¿qué fue lo último que reportó el kernel?
4. `journalctl --disk-usage` — ¿cuánto espacio ocupa tu journal actualmente?
5. `journalctl -o json-pretty -n 1` — mirá cómo se ve una sola entrada en formato estructurado (metadata completa).

---

## 9. ERROR INTENCIONAL — Break & Fix: Disco lleno / filesystem inconsistente (incidente #9 de la guía)

Vamos a simular un disco lleno usando el disco virtual `sdb`/`vg_datos` que ya tenés del Módulo 11 (no tu disco principal).

```bash
# Confirmar espacio actual en el volumen de pruebas
df -h /mnt/pruebas

# Llenarlo a propósito con un archivo grande
sudo dd if=/dev/zero of=/mnt/pruebas/archivo_gigante bs=1M count=3500 status=progress
```

(Esto va a fallar cuando se llene el volumen — ese fallo **es** el incidente)

---

## 10. DIAGNÓSTICO

1. **Síntoma:** `dd` se detiene con `No space left on device`.
2. **Observación:**
   ```bash
   df -h /mnt/pruebas
   ```
   Vas a ver `100%` de uso.
3. **Métrica:**
   ```bash
   du -sh /mnt/pruebas/* | sort -rh | head -n 5
   ```
   Identifica qué archivo(s) específicos ocupan el espacio.
4. **Log:**
   ```bash
   journalctl -p err -b | grep -i "no space\|disk\|ext4"
   ```
   Un disco lleno puede generar errores en cascada en otros servicios que intentan escribir logs/datos y fallan — este es exactamente el tipo de efecto dominó que un disco lleno provoca en sistemas reales.
5. **Causa raíz:** el archivo `archivo_gigante` que creamos a propósito consumió todo el espacio disponible del volumen.

---

## 11. SOLUCIÓN

```bash
sudo rm /mnt/pruebas/archivo_gigante
df -h /mnt/pruebas
```

**Validación:** `df -h` vuelve a mostrar espacio disponible normal.

**Nota para el mundo real:** en un servidor de producción, un disco lleno en la partición raíz (`/`) puede impedir que systemd, sshd, o incluso el propio login funcionen correctamente (muchos servicios necesitan escribir logs o archivos temporales para operar). Por eso monitorear espacio en disco (Módulo 28 — Observabilidad) es una de las alertas más básicas y críticas en cualquier infraestructura real.

---

## Checklist de cierre del módulo

- [ ] Entiendo por qué el journal de systemd reemplazó/complementa al syslog tradicional.
- [ ] Domino filtros avanzados de `journalctl` (prioridad, tiempo, unidad, UID/PID).
- [ ] Sé gestionar el tamaño del journal con `--vacuum-size`/`--vacuum-time`.
- [ ] Sé usar `dmesg` para diagnóstico de kernel/hardware.
- [ ] Puedo recitar y aplicar la metodología de 8 pasos de troubleshooting del curso.
- [ ] Completé el laboratorio Break & Fix de disco lleno (incidente #9) sin afectar mi disco principal.

---

**Próximo módulo:** 16 — Recuperación de sistemas rotos (cierre de la Fase III).
