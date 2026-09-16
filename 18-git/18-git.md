# Módulo 18 — Git

**Fase IV — Development & Automation**

---

## Objetivos del módulo

- Entender qué problema resuelve el control de versiones.
- Dominar el flujo básico: `init`, `add`, `commit`, `status`, `log`, `diff`.
- Entender y usar ramas (branches) y fusiones (merge).
- Trabajar con repositorios remotos: `clone`, `push`, `pull`, `fetch`.
- Resolver un conflicto de merge real.
- Ya tenés experiencia práctica previa: este módulo formaliza lo que veníamos haciendo con el repo `arch-linux-mastery` desde el Módulo 06.

---

## 1. CONCEPTO: ¿qué problema resuelve el control de versiones?

Sin git, versionar un proyecto a mano significaría archivos como `script_final.sh`, `script_final_v2.sh`, `script_final_v2_YA_SI.sh` — sin poder saber exactamente qué cambió entre versiones, quién lo cambió, ni volver atrás de forma confiable.

**Git resuelve esto llevando un historial completo y verificable de cada cambio**, permitiéndote:
1. Volver a cualquier versión anterior del proyecto.
2. Saber exactamente qué línea cambió, cuándo y por qué (mensaje de commit).
3. Trabajar en paralelo sobre el mismo proyecto (vos y otras personas) sin pisarse el trabajo, usando ramas.

Ya usaste esto en la práctica: cada vez que hicimos `git commit` en `arch-linux-mastery`, quedó un punto en el tiempo al que siempre podés volver.

---

## 2. CÓMO FUNCIONA: el modelo de tres áreas de git

```
Directorio de trabajo  →  Área de preparación (staging)  →  Repositorio (historial)
   (tus archivos)              (git add)                       (git commit)
```

- **Directorio de trabajo:** tus archivos tal como los ves y editás.
- **Área de preparación (staging/index):** los cambios que marcaste con `git add`, listos para ser confirmados.
- **Repositorio:** el historial permanente, cada `git commit` crea un punto fijo ahí.

**Por qué existe un paso intermedio (staging):** te permite elegir **exactamente qué cambios** van en cada commit, aunque hayas modificado varios archivos a la vez. Podés hacer `git add archivo1.txt` sin incluir `archivo2.txt` todavía, armando commits enfocados y claros en vez de "un commit gigante con todo mezclado".

---

## 3. HERRAMIENTA: comandos básicos (repaso formal de lo que ya usaste)

```bash
git init                        # convierte una carpeta en repositorio git
git status                       # ¿qué cambió? ¿qué está en staging?
git add archivo.txt               # mover un archivo al staging
git add -A                         # mover TODOS los cambios (nuevos, modificados, borrados)
git commit -m "mensaje claro"       # confirmar los cambios en staging al historial
git log                              # ver el historial de commits
git log --oneline                     # versión resumida, una línea por commit
git diff                               # ver cambios NO confirmados aún (directorio vs staging)
git diff --staged                       # ver cambios YA en staging (staging vs último commit)
```

### Buenas prácticas de mensajes de commit

Un buen mensaje explica **qué** cambió y, si no es obvio, **por qué**:
```
✅ "Agregar Módulo 18: Git"
✅ "Corregir typo en Módulo 05: memoria compartida"
❌ "cambios"
❌ "asdasd"
❌ "fix"
```

---

## 4. CÓMO FUNCIONA: ramas (branches)

Una **rama** es una línea de desarrollo independiente. La rama por defecto se llama `main` (la que venís usando).

```bash
git branch                          # ver ramas existentes, la actual marcada con *
git branch nueva-funcionalidad        # crear una rama nueva (sin moverte a ella)
git checkout nueva-funcionalidad        # moverte a esa rama
git checkout -b otra-rama                 # crear Y moverte, en un solo comando

# Trabajás, hacés commits en esa rama...

git checkout main                          # volver a main
git merge nueva-funcionalidad                # traer los cambios de esa rama a main
```

**Por qué existen las ramas:** te permiten experimentar o desarrollar algo nuevo **sin arriesgar** la versión estable de tu proyecto (`main`). Si el experimento sale mal, simplemente no la fusionás (o la borrás) y `main` nunca se vio afectado.

---

## 5. CÓMO FUNCIONA: repositorios remotos

Ya usaste esto para publicar `arch-linux-mastery` en GitHub:

```bash
git remote -v                    # ver remotos configurados (origin, en tu caso)
git push origin main               # subir tus commits locales al remoto
git pull origin main                 # traer y fusionar cambios del remoto hacia tu local
git fetch origin                      # traer cambios del remoto SIN fusionarlos todavía (más seguro para revisar antes)
git clone <url>                        # copiar un repositorio remoto completo a tu máquina
```

**Diferencia clave `pull` vs `fetch`:** `fetch` te permite ver qué cambió en el remoto antes de decidir si fusionarlo; `pull` es literalmente `fetch` + `merge` automático. En proyectos colaborativos reales, `fetch` primero es más seguro cuando no estás seguro de qué trae el remoto.

---

## 6. CÓMO FUNCIONA: `.gitignore` (repaso, ya lo usaste)

Ya creaste uno en el Módulo 06 y lo ampliaste con `/img` en este mismo curso. Le dice a git qué **nunca** debe rastrear (archivos temporales, capturas sin organizar, secretos, binarios de compilación).

---

## 7. EJEMPLO: resolver un conflicto de merge

Los conflictos ocurren cuando dos ramas modificaron **la misma línea** de un archivo de formas distintas, y git no puede decidir cuál "gana" automáticamente.

```bash
# Crear un escenario de conflicto, en un repo de prueba
mkdir ~/lab-git && cd ~/lab-git
git init
echo "línea original" > archivo.txt
git add -A && git commit -m "commit inicial"

git checkout -b rama-a
echo "cambio desde rama A" > archivo.txt
git commit -am "cambio en rama A"

git checkout main
echo "cambio desde main" > archivo.txt
git commit -am "cambio en main"

git merge rama-a
```

Esto va a generar un conflicto. Git marca el archivo así:

```
<<<<<<< HEAD
cambio desde main
=======
cambio desde rama A
>>>>>>> rama-a
```

**Para resolverlo:** editás el archivo a mano, dejando el contenido final que querés (podés quedarte con uno, el otro, o combinar ambos), borrás las marcas `<<<<<<<`, `=======`, `>>>>>>>`, y:

```bash
git add archivo.txt
git commit -m "resolver conflicto entre rama-a y main"
```

---

## 8. PRÁCTICA

1. En tu repo `arch-linux-mastery`, corré `git log --oneline` y contá cuántos commits tenés hasta ahora.
2. Creá una rama nueva `git checkout -b prueba-rama`, modificá algo menor en un archivo (ej: agregar una línea a un README), hacé commit.
3. Volvé a `main` (`git checkout main`) y fusioná esa rama (`git merge prueba-rama`).
4. Reproducí el escenario de conflicto de la sección 7 en el repo de prueba `~/lab-git`, y resolvelo.
5. `git diff --staged` después de un `git add` — practicá ver qué quedó preparado antes de confirmar el commit.

---

## 9. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
cd ~/lab-git
git commit -am "intentar commitear sin haber resuelto el conflicto anterior"
```

Si todavía tenés marcas de conflicto sin resolver, git se va a negar o vas a terminar commiteando literalmente las marcas `<<<<<<<` dentro del archivo — un error real y común en equipos que no revisan bien antes de confirmar.

**Diagnóstico:** `git status` durante un conflicto sin resolver muestra explícitamente `both modified: archivo.txt` — es la forma de confirmar que ese archivo todavía tiene el conflicto pendiente.

**Solución:** revisar el archivo, quitar las marcas, `git add`, recién ahí `git commit`.

---

## Checklist de cierre del módulo

- [ ] Entiendo el modelo de tres áreas (directorio de trabajo, staging, repositorio).
- [ ] Sé usar `add`, `commit`, `status`, `log`, `diff` con confianza.
- [ ] Sé crear ramas, moverme entre ellas, y fusionarlas.
- [ ] Entiendo la diferencia entre `pull` y `fetch`.
- [ ] Resolví un conflicto de merge real, a mano.
- [ ] Practiqué todo en mi propio repo `arch-linux-mastery`.

---

**Próximo módulo:** 19 — Python para sysadmin.
