# Módulo 23 — Virtualización (QEMU/KVM/libvirt)

**Fase V — Infrastructure & Advanced Systems**

> ⚠️ **Advertencia especial de este módulo:** estás corriendo Arch Linux **dentro de una VM de VirtualBox**. Para virtualizar *dentro* de esa VM con aceleración por hardware (KVM), tu VM necesita **virtualización anidada (nested virtualization)** habilitada — no siempre está disponible ni activada por defecto. Este módulo incluye cómo verificarlo y qué hacer si no está disponible (funciona igual, solo más lento, con emulación por software).

---

## Objetivos del módulo

- Entender la diferencia entre hipervisores tipo 1 y tipo 2, y dónde encaja KVM.
- Entender la relación entre KVM (kernel), QEMU (emulación) y libvirt (gestión).
- Verificar soporte de virtualización por hardware en tu VM.
- Crear y gestionar una VM con `virsh`/`virt-install`.

---

## 1. CONCEPTO: tipos de hipervisor

Ya usaste un hipervisor **tipo 2** todo el curso: VirtualBox corre como una aplicación más sobre tu sistema operativo anfitrión (Windows, macOS, o Linux), y este último es el que tiene control real del hardware.

Un hipervisor **tipo 1** (bare-metal) corre **directamente sobre el hardware**, sin sistema operativo anfitrión de por medio — es el propio hipervisor el que gestiona el hardware. Ejemplos: VMware ESXi, Xen, y **KVM** (que técnicamente convierte al kernel Linux mismo en un hipervisor tipo 1).

**Por qué importa la diferencia:** un hipervisor tipo 1 tiene menos overhead (no hay un SO completo "por debajo" compitiendo por recursos) — es el estándar en centros de datos y nubes públicas (AWS, GCP, Azure corren mayormente sobre KVM o hipervisores propios tipo 1).

---

## 2. CONCEPTO: KVM + QEMU + libvirt — quién hace qué

Estas tres piezas se confunden mucho porque siempre aparecen juntas. Separémoslas:

```
libvirt    → capa de GESTIÓN (API, virsh, virt-manager) — "el panel de control"
   ↓
QEMU        → EMULACIÓN de hardware (disco virtual, tarjeta de red virtual, BIOS/UEFI virtual)
   ↓
KVM          → módulo del KERNEL que da acceso a la aceleración de virtualización de la CPU (Intel VT-x / AMD-V)
```

- **KVM** (Kernel-based Virtual Machine) es un **módulo del kernel Linux** (recordá el Módulo 22: literalmente es un `.ko` que se carga como cualquier otro módulo) que expone las instrucciones de virtualización por hardware de tu CPU.
- **QEMU** puede funcionar solo (emulando una CPU completamente en software, muy lento) o **acelerado por KVM** (la CPU virtual corre casi a velocidad nativa, porque KVM le da acceso directo a las instrucciones de virtualización del procesador real).
- **libvirt** es la capa de gestión que unifica todo esto (y otros hipervisores) bajo una sola API y herramientas (`virsh`, `virt-manager`), para no tener que armar comandos de QEMU larguísimos a mano.

---

## 3. HERRAMIENTA: verificar soporte de virtualización

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

- `vmx` = soporte Intel VT-x, `svm` = soporte AMD-V.
- Si el resultado es **0**, tu VM no tiene virtualización anidada habilitada — vas a poder usar QEMU igual, pero sin aceleración KVM (mucho más lento, aunque funcional para aprender los conceptos).
- Si es mayor a 0, tenés soporte de hardware disponible.

**Si te da 0** y querés habilitarlo (opcional, depende de tu CPU física y de si VirtualBox lo expone): en VirtualBox, con la VM apagada, `Configuración → Sistema → Procesador → Habilitar VT-x/AMD-V anidado` (nested virtualization) — disponible solo en versiones recientes de VirtualBox y CPUs que lo soporten.

---

## 4. HERRAMIENTA: instalar y usar QEMU/KVM/libvirt

```bash
sudo pacman -S qemu-full libvirt virt-install virt-manager dnsmasq bridge-utils

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER    # agregar tu usuario al grupo libvirt (necesitás re-loguear después)

# Verificar que KVM está disponible para tu usuario (si aplica)
ls -l /dev/kvm
```

```bash
virsh list --all             # listar VMs gestionadas por libvirt (vacío al principio)
virsh net-list --all          # redes virtuales configuradas (libvirt crea una "default" con NAT)
```

---

## 5. EJEMPLO: crear una VM mínima con `virt-install`

Vamos a crear una VM de prueba usando el mismo ISO de Arch que ya tenés descargado (Módulo 16).

```bash
sudo virt-install \
  --name vm-prueba \
  --memory 1024 \
  --vcpus 1 \
  --disk size=5 \
  --cdrom /home/fabian/Escritorio/sistema\ operativo/archlinux-x86_64.iso \
  --os-variant archlinux \
  --network network=default \
  --graphics vnc
```

Si tu CPU **no** tiene KVM disponible dentro de esta VM (verificado en la sección 3), agregá `--virt-type qemu` explícitamente para forzar emulación por software (más lento, pero funciona):

```bash
  --virt-type qemu
```

```bash
virsh list --all       # ahora debería aparecer "vm-prueba"
virsh start vm-prueba    # si no arrancó automáticamente
virsh shutdown vm-prueba  # apagado ordenado (ACPI)
virsh destroy vm-prueba    # apagado forzado (equivalente a desenchufar)
virsh undefine vm-prueba    # eliminar la definición de la VM (no borra el disco)
```

---

## 6. PRÁCTICA

1. Corré `egrep -c '(vmx|svm)' /proc/cpuinfo` y anotá el resultado — va a determinar si tenés aceleración KVM disponible.
2. Instalá `qemu-full`, `libvirt`, `virt-install` y habilitá `libvirtd`.
3. Confirmá que tu usuario está en el grupo `libvirt` (`groups`) — si no, agregalo y volvé a loguearte (o corré `newgrp libvirt` para no tener que cerrar sesión).
4. `virsh net-list --all` — confirmá que existe la red `default`.
5. Creá una VM mínima con `virt-install` (ajustando `--virt-type` según el resultado del paso 1).
6. `virsh list --all` — confirmá que tu VM aparece definida.

---

## 7. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
virsh start vm_que_no_existe
```

**Diagnóstico:** `error: failed to get domain 'vm_que_no_existe'` — mismo patrón que venimos viendo desde el Módulo 09 (`systemctl`) y el Módulo 22 (`rmmod`): el sistema de gestión rechaza operar sobre algo que no tiene registrado, en vez de fallar de forma ambigua.

Si en cambio tu VM sí existe pero falla al arrancar con un error relacionado a `/dev/kvm` (`Could not access KVM kernel module` o similar), es la confirmación de que no tenés aceleración por hardware disponible — recordá agregar `--virt-type qemu` al crearla, o editar la configuración existente con `virsh edit vm-prueba` para cambiar el tipo de dominio.

---

## Checklist de cierre del módulo

- [ ] Entiendo la diferencia entre hipervisor tipo 1 y tipo 2, y dónde encaja KVM.
- [ ] Entiendo el rol de cada capa: KVM (aceleración), QEMU (emulación), libvirt (gestión).
- [ ] Verifiqué si tengo soporte de virtualización anidada disponible en mi VM.
- [ ] Instalé QEMU/libvirt y creé una VM (con o sin aceleración KVM, según mi hardware).
- [ ] Sé gestionar el ciclo de vida de una VM con `virsh` (start/shutdown/destroy/undefine).

---

**Próximo módulo:** 24 — Contenedores (Docker/Podman).
