# Módulo 04 — Usuarios y permisos

**Fase I — Linux Fundamentals**

---

## Objetivos del módulo

- Entender por qué Linux es multiusuario desde su diseño, no como añadido posterior.
- Entender `root` vs. usuarios normales, y por qué usar `root` todo el tiempo es peligroso.
- Leer y modificar permisos de archivos (`rwx`, notación octal).
- Usar `sudo` correctamente y entender por qué existe en vez de solo iniciar sesión como `root`.
- Entender usuarios de sistema (los que viste en `/etc/passwd`, como `http`, `dbus`).

---

## 1. CONCEPTO: Linux es multiusuario por diseño

Linux hereda de Unix (diseñado en los 70 para mainframes compartidos por muchas personas a la vez) la idea de que **el sistema siempre tiene múltiples usuarios**, cada uno con sus propios archivos, procesos y permisos — incluso si en tu VM solo existís vos como persona física. Por eso viste 22 entradas en `/etc/passwd`: la mayoría son **usuarios de sistema**, cuentas que no representan personas sino que existen para que ciertos servicios corran con privilegios acotados (por ejemplo `http` para el servidor web, `dbus` para el bus de mensajes del sistema).

**Por qué importa:** esto es una decisión de seguridad, no burocracia. Si un servicio web (corriendo como usuario `http`) es comprometido por un atacante, ese atacante queda limitado a lo que el usuario `http` puede hacer — no puede automáticamente leer tus archivos personales ni modificar el sistema completo. Vas a profundizar esto en el Módulo 29 (Ciberseguridad defensiva), pero la base se sienta acá.

---

## 2. POR QUÉ EXISTE: root vs. sudo

### El usuario root

`root` es el superusuario: no tiene ninguna restricción de permisos. Puede leer, escribir o borrar cualquier archivo, y controlar cualquier proceso.

### El problema de trabajar como root todo el tiempo

Si iniciás sesión como `root` para todo tu trabajo diario, **cualquier error de tipeo o script mal escrito puede destruir el sistema entero**, sin ninguna capa de protección. Un `rm -rf` con una ruta mal escrita, ejecutado como usuario normal, puede fallar por permisos y salvarte. El mismo comando como `root` se ejecuta sin preguntar.

### La solución: sudo

`sudo` ("superuser do") te permite ejecutar un comando puntual **con privilegios de root**, sin tener que iniciar sesión como root todo el tiempo:

```bash
sudo pacman -Syu       # ejecuta ESTE comando como root, pide tu propia contraseña
```

**Por qué es mejor que loguearte como root:**
1. **Registro de auditoría** — `sudo` deja constancia (en logs) de qué usuario ejecutó qué comando con privilegios elevados. Si sos root directamente, no hay ese rastro.
2. **Fricción intencional** — tener que escribir `sudo` cada vez te obliga a ser consciente de que estás por hacer algo con más poder del habitual.
3. **Control granular** — se puede configurar (`/etc/sudoers`) para que un usuario solo pueda ejecutar `sudo` sobre comandos específicos, no todos.

---

## 3. CÓMO FUNCIONA: permisos de archivos (`rwx`)

Recordá lo que viste en el Módulo 02 con `ls -l`:

```
-rw-r--r-- 1 fabian fabian 120 sep 10 19:00 archivo.txt
```

Desglosemos los primeros 10 caracteres:

```
-  rw-  r--  r--
│   │    │    │
│   │    │    └── permisos para "otros" (everyone else)
│   │    └─────── permisos para el GRUPO dueño del archivo
│   └──────────── permisos para el USUARIO dueño del archivo
└──────────────── tipo de archivo (- = archivo normal, d = directorio, l = symlink)
```

Cada bloque de 3 caracteres representa:

| Símbolo | Significado | Para archivos | Para directorios |
|---|---|---|---|
| `r` | read (lectura) | Ver contenido | Listar contenido (`ls`) |
| `w` | write (escritura) | Modificar contenido | Crear/borrar archivos dentro |
| `x` | execute (ejecución) | Ejecutar como programa/script | Entrar al directorio (`cd`) |
| `-` | ausencia del permiso | — | — |

### Notación octal (la que vas a usar para cambiar permisos)

Cada permiso vale un número: `r=4`, `w=2`, `x=1`. Se suman por bloque:

```
rwx = 4+2+1 = 7
rw- = 4+2   = 6
r-x = 4+1   = 5
r-- = 4     = 4
```

Entonces `rw-r--r--` se representa como `644` (usuario=6, grupo=4, otros=4).

```bash
chmod 644 archivo.txt      # dueño lee/escribe, resto solo lee
chmod 755 script.sh         # dueño lee/escribe/ejecuta, resto lee/ejecuta (típico para scripts y programas)
chmod +x script.sh          # forma alternativa: solo agrega permiso de ejecución
chown fabian:fabian archivo.txt   # cambia el dueño (usuario:grupo) del archivo
```

---

## 4. HERRAMIENTA: comandos de usuarios y permisos

```bash
whoami                    # ¿qué usuario soy ahora?
id                          # info completa: UID, GID, grupos a los que pertenezco
groups                      # a qué grupos pertenece mi usuario
sudo -l                     # qué comandos puedo ejecutar con sudo
su - otrousuario            # cambiar de sesión a otro usuario (pide su contraseña)
sudo useradd -m nuevo       # crear un usuario nuevo (con carpeta home) — requiere root
sudo passwd nuevo           # asignarle contraseña
sudo usermod -aG grupo usuario   # agregar un usuario a un grupo adicional
```

### El grupo `wheel` en Arch

En Arch Linux, por convención, los usuarios que pueden usar `sudo` deben pertenecer al grupo `wheel` (y ese grupo debe estar habilitado en `/etc/sudoers`, algo que normalmente ya se configuró cuando instalaste tu sistema o creaste tu usuario). Podés confirmarlo con:

```bash
groups fabian
```

Si ves `wheel` en la lista, tenés permiso para usar `sudo` (asumiendo que el archivo `sudoers` lo tiene habilitado).

---

## 5. EJEMPLO

```bash
whoami                     # fabian
id                          # ver tu UID, GID y grupos
groups                      # confirmar si estás en "wheel"

# Crear un archivo y experimentar con permisos
touch ~/lab04/secreto.txt
chmod 600 ~/lab04/secreto.txt   # solo el dueño puede leer/escribir, nadie más
ls -l ~/lab04/secreto.txt

chmod 644 ~/lab04/secreto.txt   # ahora cualquiera puede leerlo (pero no modificarlo)
ls -l ~/lab04/secreto.txt
```

---

## 6. PRÁCTICA

1. `whoami` y `id` — pasame el resultado completo de `id`.
2. `groups` — ¿aparece `wheel` en la lista?
3. Creá `~/lab04/test.sh` con `touch`, dale permisos de ejecución con `chmod +x`, y confirmá con `ls -l` que ahora tiene la `x`.
4. Probá `sudo whoami` — ¿qué usuario te devuelve? (Debería decir `root`, confirmando que el comando se ejecutó con privilegios elevados aunque vos seguís siendo `fabian`).
5. Ahora que entendés permisos: ¿por qué antes en el Módulo 02 no podías leer `/var/log/audit` con tu usuario normal? Probá `sudo du -sh /var/log/audit` y compará con el resultado que te había dado sin `sudo`.

---

## 7. ERROR INTENCIONAL (Break & Fix simulado)

```bash
touch ~/lab04/bloqueado.txt
chmod 000 ~/lab04/bloqueado.txt
cat ~/lab04/bloqueado.txt
```

`chmod 000` quita **todos** los permisos, incluso para el dueño.

---

## 8. DIAGNÓSTICO

- **Síntoma:** `cat: bloqueado.txt: Permission denied`, a pesar de que sos el dueño del archivo.
- **Causa raíz:** los permisos del archivo (`000`) no le dan ni siquiera al dueño el permiso de lectura. Ser "dueño" de un archivo no te da acceso automático — los permisos son la única fuente de verdad, incluso contra vos mismo.
- **Nota importante:** `root` sí podría leerlo igual, porque root ignora los permisos normales del sistema de archivos (esto conecta con por qué root es tan poderoso y peligroso).

---

## 9. SOLUCIÓN

```bash
chmod 644 ~/lab04/bloqueado.txt   # devolvés permiso de lectura al dueño
cat ~/lab04/bloqueado.txt          # ahora funciona
```

**Rollback:** si te trabaste completamente con un archivo tuyo en `000` y no podés ni cambiarle el permiso (no debería pasar como dueño, pero si pasara con otro usuario), la salida es usar `sudo chmod`.

---

## 10. RETO (rápido)

Explicá en una frase: ¿por qué el usuario `http` (que corre el servidor web) NO debería tener bash como shell ni permisos de lectura sobre `/home/fabian`? Conectalo con el principio de **menor privilegio** (dar a cada proceso/usuario solo el acceso mínimo que necesita para funcionar).

---

## Checklist de cierre del módulo

- [ ] Entiendo por qué Linux es multiusuario y qué son los usuarios de sistema.
- [ ] Sé la diferencia entre root y sudo, y por qué sudo es más seguro que loguearse como root.
- [ ] Puedo leer una línea de permisos (`rwx`) y convertirla a notación octal.
- [ ] Sé usar `chmod` y `chown`.
- [ ] Completé la práctica y el error intencional en mi VM.

---

**Próximo módulo:** 05 — Procesos.
