# Módulo 08 — AUR y PKGBUILD

**Fase II — Arch Linux Core**

---

## Objetivos del módulo

- Entender qué es el AUR y por qué existe además de los repositorios oficiales.
- Entender qué es un PKGBUILD y cómo se construye un paquete desde cero.
- Usar un helper de AUR (`yay` o `paru`) de forma segura.
- Entender el riesgo de seguridad real del AUR y cómo mitigarlo (revisar antes de confiar).

---

## 1. CONCEPTO: ¿qué es el AUR?

El **AUR** (Arch User Repository) es un repositorio **mantenido por la comunidad**, no por el equipo oficial de Arch. No contiene paquetes compilados y listos como los repos oficiales (`core`, `extra`) — contiene **recetas de compilación** (los PKGBUILD) que cualquier usuario puede subir, describiendo cómo descargar, compilar e instalar un programa.

**Por qué existe:** los repositorios oficiales de Arch son mantenidos por un equipo reducido que garantiza calidad y seguridad, así que no pueden (ni deberían) empaquetar cada programa que existe en internet. El AUR resuelve esto delegando esa curación a la comunidad: cualquiera puede publicar cómo instalar un programa, y otros usuarios lo usan, lo revisan y comentan si algo falla.

---

## 2. POR QUÉ EXISTE: el riesgo de seguridad y cómo se mitiga

### El problema real

Como el AUR es contenido subido por usuarios sin revisión centralizada de seguridad, **un PKGBUILD malicioso podría, en teoría, ejecutar cualquier comando en tu sistema** (porque compilar software implica ejecutar scripts arbitrarios con tus permisos). Esto no es teórico — han existido casos reales de paquetes maliciosos subidos al AUR y luego eliminados al ser detectados.

### La mitigación

1. **Nunca instales un paquete del AUR sin revisar el PKGBUILD primero** (es un archivo de texto legible, no binario).
2. Preferí paquetes con muchos votos y comentarios recientes positivos.
3. Usá un **helper de AUR** (como `yay` o `paru`) que automatiza el proceso, pero siempre revisando qué es lo que vas a ejecutar antes de confirmar.

Esto conecta directamente con la Fase V del curso (Ciberseguridad defensiva, Módulo 29): la idea de **nunca confiar ciegamente en código que vas a ejecutar con tus privilegios**, sin importar la fuente.

---

## 3. CÓMO FUNCIONA: anatomía de un PKGBUILD

Un PKGBUILD es un script de bash con variables y funciones estandarizadas que `makepkg` (la herramienta oficial de compilación de paquetes de Arch) sabe interpretar:

```bash
pkgname=ejemplo
pkgver=1.0.0
pkgrel=1
pkgdesc="Descripción corta del programa"
arch=('x86_64')
url="https://ejemplo.com"
license=('MIT')
depends=('glibc')          # dependencias necesarias para EJECUTAR el programa
makedepends=('gcc' 'make') # dependencias necesarias solo para COMPILARLO
source=("https://ejemplo.com/$pkgname-$pkgver.tar.gz")
sha256sums=('...')          # verificación de integridad del código fuente descargado

build() {
    cd "$pkgname-$pkgver"
    make
}

package() {
    cd "$pkgname-$pkgver"
    make DESTDIR="$pkgdir" install
}
```

**Qué mirar cuando revisás un PKGBUILD ajeno antes de confiar en él:**
- La sección `source=(...)`: ¿de dónde descarga realmente el código? ¿Es el sitio oficial del proyecto?
- Cualquier línea con `curl`, `wget`, `rm -rf`, o `sudo` dentro de las funciones — son señales de alerta si no tienen justificación clara.
- Los `sha256sums`: verifican que el archivo descargado no fue alterado.

---

## 4. HERRAMIENTA: instalar un helper de AUR (`yay`)

`yay` no está en los repos oficiales (irónicamente, hay que instalarlo *como si fuera* un paquete de AUR, a mano, la primera vez):

```bash
sudo pacman -S --needed base-devel git   # herramientas necesarias para compilar cualquier PKGBUILD
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si     # compila (-s instala dependencias) e instala (-i) el resultado
```

Una vez instalado, `yay` funciona con una sintaxis muy similar a `pacman`, pero busca tanto en repos oficiales como en el AUR:

```bash
yay -S nombre-paquete     # instala desde repos oficiales O AUR, buscando automáticamente
yay -Ss texto              # busca en ambos
yay -Syu                    # actualiza sistema completo + paquetes de AUR instalados
```

---

## 5. EJEMPLO

```bash
# Buscar un paquete que solo existe en AUR (ejemplo: visual-studio-code-bin)
yay -Ss visual-studio-code

# Antes de instalar, inspeccionar el PKGBUILD manualmente
git clone https://aur.archlinux.org/visual-studio-code-bin.git
cat visual-studio-code-bin/PKGBUILD

# Si todo se ve bien, instalar con yay
yay -S visual-studio-code-bin
```

---

## 6. PRÁCTICA

1. Instalá `base-devel` y `git` si no los tenés: `sudo pacman -S --needed base-devel git`.
2. Instalá `yay` siguiendo los pasos de la sección 4.
3. `yay -Ss neofetch` (o algún paquete similar de tu interés) — ¿aparece disponible?
4. Antes de instalar cualquier cosa del AUR, cloná su repositorio y mostrá el PKGBUILD con `cat` — practicá el hábito de revisar antes de confiar.
5. `yay -Qm` — este flag lista específicamente los paquetes instalados que vienen del AUR (no de los repos oficiales). Después de instalar algo, confirmá que aparece ahí.

---

## 7. ERROR INTENCIONAL / DIAGNÓSTICO

Un error común al compilar paquetes de AUR:

```bash
makepkg -si
```
Puede fallar con algo como `error: target not found` o errores de compilación si faltan `makedepends`. La causa más común es no haber instalado `base-devel` primero (el conjunto de herramientas de compilación: `gcc`, `make`, `patch`, etc.), que es justamente el primer paso que indicamos en la sección 4.

**Diagnóstico general:** si `makepkg` falla, leé el error completo — casi siempre indica qué dependencia falta o qué paso de compilación no pudo completarse, siguiendo el mismo principio que venimos aplicando desde el Módulo 01: leer el mensaje completo antes de asumir nada.

---

## Checklist de cierre del módulo

- [ ] Entiendo qué es el AUR y por qué existe además de los repos oficiales.
- [ ] Entiendo el riesgo de seguridad del AUR y cómo mitigarlo (revisar PKGBUILD antes de confiar).
- [ ] Sé leer la estructura básica de un PKGBUILD.
- [ ] Instalé `yay` manualmente siguiendo el proceso completo.
- [ ] Instalé al menos un paquete de AUR revisando su PKGBUILD antes.

---

**Próximo módulo:** 09 — systemd.
