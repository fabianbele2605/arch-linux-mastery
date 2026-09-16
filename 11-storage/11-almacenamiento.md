# Módulo 11 — Almacenamiento (particiones, filesystems, LVM, RAID, LUKS)

**Fase II — Arch Linux Core**

Con este módulo cerramos la Fase II.

> ⚠️ Este módulo incluye experimentación con discos virtuales adicionales, no con tu disco principal (`sda`). No hace falta tocar `sda` para nada de lo que sigue — vamos a agregar un disco virtual nuevo y vacío en VirtualBox para practicar con seguridad total.

---

## Objetivos del módulo

- Repasar y profundizar particiones y filesystems (ya vistos parcialmente en Módulos 02 y 06).
- Entender LVM (Logical Volume Manager) y el problema que resuelve.
- Entender RAID por software (`mdadm`) y sus niveles principales.
- Entender cifrado de disco con LUKS y por qué importa incluso en una VM de estudio.
- Practicar con un disco virtual adicional, sin riesgo para tu sistema actual.

---

## 1. CONCEPTO: repaso — particiones y filesystems

Ya viste esto en acción en los Módulos 02 y 06: un disco físico (`sda`) se divide en particiones (`sda1`, `sda2`), y cada partición se formatea con un filesystem (ext4, vfat) que le da estructura para poder guardar archivos. Este módulo agrega tres capas más de sofisticación que las herramientas profesionales de almacenamiento ofrecen por encima de esa base.

---

## 2. POR QUÉ EXISTE: LVM (Logical Volume Manager)

### El problema que resuelve

Con particiones tradicionales, el tamaño se fija al crearlas y es **muy difícil cambiarlo después** sin arriesgar los datos (hay que mover/redimensionar particiones vecinas, con herramientas delicadas). Si tu partición `/home` se queda sin espacio, no podés simplemente "agrandarla" con una operación segura y sencilla.

### La solución de LVM

LVM agrega una capa de abstracción entre las particiones físicas y los filesystems:

```
Discos físicos (sda, sdb...)
        ↓
Physical Volumes (PV)      ← particiones marcadas para uso de LVM
        ↓
Volume Group (VG)           ← "pool" de espacio que junta uno o más PVs
        ↓
Logical Volumes (LV)         ← "particiones virtuales" creadas del pool, con el tamaño que quieras
        ↓
Filesystem (ext4, etc.)
```

**Por qué es mejor:** si necesitás más espacio para un Logical Volume, simplemente le asignás más espacio del Volume Group (o agregás un disco físico nuevo al VG) y **redimensionás el LV en caliente**, sin mover datos de particiones vecinas. Es la razón por la que casi todos los servidores de producción reales usan LVM en vez de particiones tradicionales directas.

---

## 3. POR QUÉ EXISTE: RAID por software

### El problema que resuelve

Un solo disco es un punto único de falla: si se rompe, perdés los datos (a menos que tengas backups, tema del Módulo 15/17). RAID combina múltiples discos físicos para lograr **redundancia** (tolerancia a fallos) y/o **rendimiento**.

### Niveles principales

| Nivel | Qué hace | Tolerancia a fallos |
|---|---|---|
| RAID 0 | Divide datos entre discos (stripe) — más velocidad, sin redundancia | Ninguna — si falla un disco, se pierde todo |
| RAID 1 | Duplica los datos exactos en dos discos (mirror) | Tolera la falla de 1 disco |
| RAID 5 | Distribuye datos + paridad entre 3+ discos | Tolera la falla de 1 disco |
| RAID 10 | Combina mirror + stripe | Tolera fallas según configuración |

En Linux, el software estándar para RAID es `mdadm`. **Importante:** RAID no es un reemplazo de backups — protege contra la falla de un disco físico, no contra errores humanos (`rm -rf` accidental) ni ransomware. Esto lo vas a retomar en el Módulo 15 (Backups).

---

## 4. POR QUÉ EXISTE: LUKS (cifrado de disco)

**LUKS** (Linux Unified Key Setup) cifra una partición completa a nivel de bloque, de forma que sin la contraseña/clave correcta, los datos son ilegibles — incluso si alguien extrae físicamente el disco.

**Por qué importa incluso en una VM de estudio:** es la práctica estándar en la industria para cualquier laptop, servidor o dispositivo que pueda perderse o ser robado. Vas a practicarlo acá para entender el mecanismo, aunque tu VM actual no lo tenga configurado.

---

## 5. HERRAMIENTA: preparar un disco virtual de práctica

Primero, agregá un disco virtual nuevo (vacío) a tu VM desde VirtualBox: **Configuración de la VM → Almacenamiento → Agregar disco duro → Crear uno nuevo, 5-10 GB, formato VDI**. Con la VM apagada o usando el controlador de "hot-plug" si tu configuración lo permite. Iniciá la VM después de agregarlo.

Verificalo:
```bash
lsblk
```
Vas a ver un disco nuevo, probablemente `sdb`, sin particiones.

---

## 6. EJEMPLO: LVM paso a paso

```bash
# Instalar herramientas de LVM (probablemente no vienen por defecto)
sudo pacman -S lvm2

# Marcar el disco completo como Physical Volume
sudo pvcreate /dev/sdb
sudo pvdisplay

# Crear un Volume Group que use ese PV
sudo vgcreate vg_datos /dev/sdb
sudo vgdisplay

# Crear un Logical Volume de, por ejemplo, 3GB dentro del VG
sudo lvcreate -L 3G -n lv_pruebas vg_datos
sudo lvdisplay

# Formatear y montar el LV como cualquier partición normal
sudo mkfs.ext4 /dev/vg_datos/lv_pruebas
sudo mkdir /mnt/pruebas
sudo mount /dev/vg_datos/lv_pruebas /mnt/pruebas
df -h | grep pruebas
```

### Redimensionar en caliente (la magia de LVM)

```bash
sudo lvextend -L +1G /dev/vg_datos/lv_pruebas   # agregar 1GB más al LV
sudo resize2fs /dev/vg_datos/lv_pruebas          # extender el filesystem para usar el nuevo espacio
df -h | grep pruebas                              # confirmar el nuevo tamaño
```

---

## 7. EJEMPLO: LUKS paso a paso

> Vamos a cifrar un Logical Volume nuevo, distinto al que usamos arriba, para no interferir.

```bash
sudo lvcreate -L 2G -n lv_cifrado vg_datos

# Cifrar el volumen (te va a pedir una contraseña, ¡no la olvides!)
sudo cryptsetup luksFormat /dev/vg_datos/lv_cifrado

# Abrir (desbloquear) el volumen cifrado — pide la contraseña
sudo cryptsetup open /dev/vg_datos/lv_cifrado datos_seguros

# Ahora existe /dev/mapper/datos_seguros — se usa como cualquier partición
sudo mkfs.ext4 /dev/mapper/datos_seguros
sudo mkdir /mnt/seguro
sudo mount /dev/mapper/datos_seguros /mnt/seguro

# Para cerrar (volver a cifrar/bloquear) cuando termines:
sudo umount /mnt/seguro
sudo cryptsetup close datos_seguros
```

Una vez cerrado con `cryptsetup close`, el contenido es completamente ilegible sin volver a abrirlo con la contraseña correcta — probalo intentando montar `/dev/vg_datos/lv_cifrado` directamente sin abrirlo primero, y vas a ver que falla (porque el kernel ve solo datos cifrados, sin estructura de filesystem reconocible).

---

## 8. PRÁCTICA

1. Agregá el disco virtual nuevo y confirmá con `lsblk` que aparece como `sdb`.
2. Completá el ejemplo de LVM completo: `pvcreate` → `vgcreate` → `lvcreate` → formatear → montar.
3. Escribí un archivo de prueba dentro de `/mnt/pruebas` y confirmá que persiste.
4. Extendé el LV con `lvextend` + `resize2fs`, y confirmá el nuevo tamaño con `df -h`.
5. Completá el ejemplo de LUKS: creá el volumen cifrado, ábrelo, formateálo, montálo, escribí algo, y luego cerralo con `cryptsetup close`.
6. Intentá `sudo mount /dev/vg_datos/lv_cifrado /mnt/seguro` (sin abrirlo primero con `cryptsetup open`) — confirmá que falla, y entendé por qué.

---

## 9. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
sudo lvremove /dev/vg_datos/lv_pruebas
```
(sin haber desmontado antes)

Vas a obtener un error indicando que el volumen está en uso/montado. **Causa raíz:** el kernel no permite eliminar un volumen lógico mientras tiene un filesystem montado activo — protección contra pérdida accidental de datos.

**Solución:**
```bash
sudo umount /mnt/pruebas
sudo lvremove /dev/vg_datos/lv_pruebas
```

---

## Checklist de cierre del módulo (y de la Fase II completa)

- [ ] Entiendo la jerarquía PV → VG → LV de LVM y por qué existe.
- [ ] Sé crear, montar y **redimensionar en caliente** un Logical Volume.
- [ ] Entiendo los niveles básicos de RAID (0, 1, 5, 10) y sus trade-offs.
- [ ] Entiendo cómo funciona LUKS y practiqué cifrar/abrir/cerrar un volumen.
- [ ] Completé la práctica completa en el disco virtual adicional (sin tocar `sda`).

---

## Cierre de Fase II — Arch Linux Core

Con este módulo termina la Fase II: instalación, pacman/AUR, systemd, boot, y almacenamiento avanzado. Ya tenés una base sólida de administración de un sistema Arch completo — desde cómo arranca hasta cómo se organiza su almacenamiento en las capas más profesionales.

---

**Próximo módulo:** 12 — Networking (inicio de la Fase III — Networking & Security).
