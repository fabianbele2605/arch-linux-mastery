# Módulo 07 — pacman y gestión de paquetes

**Fase II — Arch Linux Core**

---

## Objetivos del módulo

- Entender qué es un gestor de paquetes y qué problema resuelve.
- Dominar el ciclo de vida completo con `pacman`: instalar, actualizar, buscar, eliminar, consultar.
- Entender repositorios, sincronización de bases de datos y caché de paquetes.
- Instalar por fin `man-db`/`man-pages` (la deuda pendiente del Módulo 01).
- Entender el concepto de dependencias y por qué a veces `pacman` se "traba" pidiendo confirmar cosas.

---

## 1. CONCEPTO: ¿qué es un gestor de paquetes?

Un **paquete** es un archivo comprimido que contiene un programa (sus binarios, configuración por defecto, metadatos) listo para instalarse. Un **gestor de paquetes** es la herramienta que:

1. Descarga paquetes desde repositorios (servidores remotos con software verificado).
2. Resuelve **dependencias** (si el programa A necesita la librería B, la instala automáticamente).
3. Lleva un registro de qué está instalado, para poder actualizar o desinstalar de forma limpia.
4. Verifica integridad (firmas criptográficas) para evitar instalar software corrupto o malicioso.

**Por qué existe:** sin un gestor de paquetes, instalar software significaría descargar código fuente, compilarlo manualmente, resolver a mano cada dependencia, y no tener ningún registro centralizado de qué versión de qué tenés instalada. Sería inviable a escala y extremadamente inseguro.

En Arch, el gestor de paquetes es **pacman** (Package Manager), y su complemento para software no oficial es el **AUR** (Arch User Repository), que vas a ver en el Módulo 08.

---

## 2. POR QUÉ EXISTE: repositorios y bases de datos locales

pacman no "busca en internet" cada vez que le pedís algo. Mantiene una **base de datos local** (una lista descargada de qué paquetes existen, en qué versión, en qué repositorio) que tenés que sincronizar periódicamente:

```bash
sudo pacman -Sy      # sincroniza (Sync) la base de datos de paquetes con los repositorios remotos
```

**Advertencia importante que vas a ver en cualquier documentación de Arch:** nunca uses `-Sy` solo, sin actualizar también los paquetes instalados (`-Syu`), porque puede generar una desincronización entre versiones de paquetes y sus dependencias (esto se conoce como "partial upgrades" y es una causa clásica de sistemas rotos en Arch — anotalo para el Módulo 16).

```bash
sudo pacman -Syu     # sincroniza Y actualiza TODO el sistema — la forma correcta de actualizar
```

---

## 3. CÓMO FUNCIONA: anatomía de los flags de pacman

pacman usa un esquema de "operación principal + letra minúscula = modificador":

| Comando | Qué hace |
|---|---|
| `pacman -S <paquete>` | Instala un paquete (Sync — lo trae del repositorio) |
| `pacman -Syu` | Sincroniza base de datos y actualiza todo el sistema |
| `pacman -R <paquete>` | Elimina un paquete (Remove) |
| `pacman -Rs <paquete>` | Elimina un paquete Y sus dependencias que ya no usa nadie más |
| `pacman -Rns <paquete>` | Elimina paquete + dependencias + archivos de configuración (limpieza total) |
| `pacman -Q` | Lista paquetes instalados (Query) |
| `pacman -Qi <paquete>` | Info detallada de un paquete instalado |
| `pacman -Qs <texto>` | Busca entre paquetes YA instalados |
| `pacman -Ss <texto>` | Busca en los repositorios remotos (no instalados todavía) |
| `pacman -Qdt` | Lista dependencias huérfanas (instaladas como dependencia, ya no usadas) |
| `pacman -Sc` | Limpia la caché de paquetes descargados que ya no están instalados |

---

## 4. HERRAMIENTA: instalar man-db (deuda del Módulo 01)

Ahora que sabés instalar paquetes, vamos a resolver algo pendiente:

```bash
sudo pacman -S man-db man-pages
```

Esto va a mostrar un resumen de lo que se va a instalar (incluyendo dependencias) y te va a pedir confirmación (`Enter` para sí, por defecto). Después de instalado:

```bash
man ls          # ahora sí debería funcionar
man pacman       # el manual del propio pacman, con TODOS los flags que existen
```

---

## 5. CÓMO FUNCIONA: dependencias y por qué a veces pacman "no te deja"

Cuando intentás eliminar un paquete que otro paquete necesita, pacman se va a negar:

```bash
sudo pacman -R glibc
```

Esto va a fallar (o advertir fuertemente) porque `glibc` es una librería fundamental de la que depende casi todo el sistema. pacman **protege el sistema** rehusándose a romper dependencias activas. Esto es intencional — es mucho mejor que pacman te frene a que borres algo y tu sistema deje de arrancar.

---

## 6. EJEMPLO

```bash
# Buscar si un paquete existe en los repos, antes de instalarlo
pacman -Ss htop

# Instalarlo
sudo pacman -S htop

# Ver información detallada de lo que se instaló
pacman -Qi htop

# Ver qué archivos trajo consigo
pacman -Ql htop

# Ver el tamaño total de la caché de paquetes descargados
du -sh /var/cache/pacman/pkg/
```

---

## 7. PRÁCTICA

1. Instalá `man-db` y `man-pages` como se indicó arriba, y confirmá que `man ls` ya funciona.
2. `pacman -Q | wc -l` — ¿cuántos paquetes tenés instalados en total en tu sistema?
3. `pacman -Ss htop` — ¿aparece disponible en los repos? Instalalo con `sudo pacman -S htop` y abrilo (`htop`, salís con `q`).
4. `pacman -Qdt` — ¿tenés dependencias huérfanas acumuladas? (Es normal tener algunas o ninguna en un sistema poco usado.)
5. `du -sh /var/cache/pacman/pkg/` — ¿cuánto espacio ocupa tu caché de paquetes descargados?

---

## 8. ERROR INTENCIONAL

```bash
sudo pacman -S paquete-que-no-existe-123456
```

---

## 9. DIAGNÓSTICO Y SOLUCIÓN

Vas a obtener `error: target not found: paquete-que-no-existe-123456`. Esto significa que pacman consultó su base de datos local y ese nombre exacto no existe en ningún repositorio configurado. Causas reales de este error en la vida real:

- Error de tipeo en el nombre.
- El paquete existe pero con otro nombre (usar `pacman -Ss palabra_clave` para buscar por texto parcial en vez de nombre exacto).
- El paquete no está en los repos oficiales, sino en el **AUR** (Módulo 08) — pacman no busca ahí por defecto.
- Tu base de datos local está desactualizada (`sudo pacman -Sy` para refrescarla — aunque, como vimos, siempre preferí `-Syu` completo).

---

## Checklist de cierre del módulo

- [ ] Entiendo qué es un gestor de paquetes y por qué existe.
- [ ] Sé instalar, buscar, consultar y eliminar paquetes con pacman.
- [ ] Instalé `man-db`/`man-pages` y ahora tengo manuales completos disponibles.
- [ ] Entiendo por qué nunca se usa `-Sy` solo, sin actualizar todo el sistema.
- [ ] Completé la práctica y el error intencional en mi VM.

---

**Próximo módulo:** 08 — AUR y PKGBUILD.
