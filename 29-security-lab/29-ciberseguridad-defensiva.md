# Módulo 29 — Ciberseguridad defensiva

**Fase V — Infrastructure & Advanced Systems**

Con este módulo cerramos la parte "core" de la Fase V (queda el Módulo 30 como cierre conceptual del curso).

---

## Objetivos del módulo

- Consolidar el principio de menor privilegio aplicado en todo el curso.
- Auditar tu propio sistema con `lynis` y entender sus hallazgos.
- Detectar intentos de intrusión con `auditd` y `journalctl`.
- Endurecer SSH más allá de lo visto en el Módulo 13.
- Escanear tu sistema en busca de rootkits.
- Simular y detectar un ataque de fuerza bruta contra SSH (con `fail2ban` del Módulo 14 protegiendo).

---

## 1. CONCEPTO: seguridad defensiva como práctica continua, no un checklist único

Todo el curso construyó, sin que lo llamáramos "seguridad" explícitamente, una base defensiva real:

| Módulo | Qué aportó a la seguridad |
|---|---|
| 04 — Usuarios y permisos | Menor privilegio: cada proceso con el mínimo acceso necesario |
| 08 — AUR/PKGBUILD | Nunca confiar en código sin revisar antes de ejecutar |
| 13 — SSH | Autenticación por clave, no contraseña |
| 14 — Firewall | Denegar por defecto, permitir explícitamente |
| 15 — Logs | Diagnóstico basado en evidencia, no suposición |
| 26 — PostgreSQL | Roles con permisos limitados, prevención de SQL injection |

Este módulo formaliza esa disciplina y agrega herramientas específicas de auditoría.

---

## 2. HERRAMIENTA: `lynis` — auditoría de seguridad del sistema

```bash
sudo pacman -S lynis
sudo lynis audit system
```

`lynis` recorre tu sistema completo (usuarios, SSH, firewall, kernel, paquetes) y genera un **hardening index** (0-100) con sugerencias concretas de mejora, cada una con un identificador (ej: `SSH-7408`) que podés buscar en su documentación.

```bash
sudo lynis show details SSH-7408   # detalle de una sugerencia específica
```

**Cómo interpretar los resultados:** no todas las sugerencias aplican a tu contexto (algunas son para servidores de producción expuestos a internet, no para una VM de estudio) — la habilidad real es **evaluar** cada hallazgo, no aplicar todo ciegamente.

---

## 3. HERRAMIENTA: `auditd` — auditoría a nivel de kernel

```bash
sudo pacman -S audit
sudo systemctl enable --now auditd

# Auditar accesos a un archivo sensible
sudo auditctl -w /etc/passwd -p wa -k cambios_usuarios

# Ver los eventos registrados
sudo ausearch -k cambios_usuarios
```

**Por qué existe (conexión con el Módulo 22):** `auditd` usa el subsistema de auditoría del propio kernel Linux — el mismo tipo de mecanismo de bajo nivel que exploraste con módulos de kernel, pero aplicado específicamente a registrar **quién hizo qué** sobre archivos y syscalls sensibles, con nivel de detalle forense.

---

## 4. CÓMO FUNCIONA: hardening adicional de SSH

Más allá de lo visto en el Módulo 13 (autenticación por clave):

```bash
sudo nano /etc/ssh/sshd_config
```

```
MaxAuthTries 3            # cortar la conexión tras 3 intentos fallidos
LoginGraceTime 20          # tiempo límite para autenticarse tras conectar
AllowUsers fabian            # lista blanca explícita de quién puede entrar por SSH
Protocol 2                    # forzar el protocolo SSH2 (el 1 es obsoleto e inseguro)
X11Forwarding no                # deshabilitar si no lo necesitás
```

```bash
sudo sshd -t          # validar sintaxis (recordá: siempre antes de aplicar)
sudo systemctl restart sshd
```

**Advertencia del Módulo 13, repetida a propósito:** mantené tu sesión SSH actual abierta al reiniciar el servicio — el mismo riesgo de bloqueo que ya viviste ahí.

---

## 5. HERRAMIENTA: detección de rootkits

```bash
sudo pacman -S rkhunter
sudo rkhunter --update
sudo rkhunter --check --skip-keypress
```

`rkhunter` (Rootkit Hunter) compara el estado de binarios del sistema contra firmas conocidas de rootkits, y detecta anomalías (permisos sospechosos, procesos ocultos, módulos de kernel no estándar — conexión directa con el Módulo 22).

---

## 6. EJEMPLO: simular y detectar fuerza bruta contra SSH

Ya tenés `fail2ban` protegiendo SSH desde el Módulo 14. Verifiquemos que realmente actúa:

```bash
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```

Simulá varios intentos fallidos (desde otra terminal, conectándote con un usuario que no existe):

```bash
for i in {1..5}; do ssh usuario_invalido@localhost -o PasswordAuthentication=yes -o PubkeyAuthentication=no 2>&1 | tail -1; done
```

```bash
sudo fail2ban-client status sshd
sudo journalctl -u fail2ban | tail -20
```

Deberías ver que tu IP (`127.0.0.1` en este caso) queda listada como baneada tras superar `maxretry` — protección automática funcionando, sin intervención manual.

---

## 7. PRÁCTICA

1. Corré `lynis audit system` completo y anotá tu hardening index inicial.
2. Elegí 3 hallazgos de `lynis` y decidí, justificando por qué, si aplican a tu VM de estudio o no.
3. Configurá `auditd` para vigilar `/etc/passwd` y `/etc/shadow`, y generá un evento de prueba (ej: `sudo touch /etc/passwd` no cambia nada real, pero genera el evento de auditoría).
4. Aplicá el hardening adicional de SSH de la sección 4, validando con `sshd -t` antes de reiniciar.
5. Corré `rkhunter --check` y revisá el resumen final.
6. Simulá el ataque de fuerza bruta de la sección 6 y confirmá que `fail2ban` reacciona.

---

## 8. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
sudo nano /etc/ssh/sshd_config
```
Agregá `AllowUsers usuario_que_no_existe` (en vez de tu propio usuario), guardá, y reiniciá:
```bash
sudo systemctl restart sshd
ssh fabian@localhost
```

**Diagnóstico:** vas a quedar bloqueado — `AllowUsers` es una lista blanca estricta, y si tu propio usuario no está en ella, ni siquiera con la clave correcta vas a poder entrar. El log (`sudo journalctl -u sshd -n 10`) va a mostrar explícitamente `User fabian not allowed because not listed in AllowUsers`.

**Solución:** corregir `AllowUsers fabian`, `sshd -t`, `systemctl restart sshd` — con la sesión de consola de VirtualBox como red de seguridad si te bloqueaste completamente (mismo patrón del Módulo 13).

---

## Checklist de cierre del módulo

- [ ] Entiendo cómo cada módulo anterior contribuyó a una postura de seguridad defensiva.
- [ ] Corrí `lynis` y evalué críticamente sus hallazgos (no aplicando todo ciegamente).
- [ ] Configuré `auditd` para vigilar archivos sensibles.
- [ ] Endurecí SSH más allá del Módulo 13, validando antes de aplicar.
- [ ] Escaneé mi sistema con `rkhunter`.
- [ ] Simulé un ataque de fuerza bruta y confirmé que `fail2ban` responde automáticamente.

---

**Próximo módulo:** 30 — Fundamentos de OS Development (cierre del curso).
