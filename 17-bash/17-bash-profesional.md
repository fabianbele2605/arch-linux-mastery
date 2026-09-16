# Módulo 17 — Bash profesional

**Fase IV — Development & Automation**

---

## Objetivos del módulo

- Escribir scripts de bash reales, no solo comandos sueltos en la terminal.
- Dominar variables, condicionales, bucles, funciones y argumentos.
- Manejar errores correctamente (`set -e`, `set -o pipefail`, `trap`).
- Entender por fin la sintaxis heredoc que usamos (y evitamos) en módulos anteriores.
- Escribir el primer proyecto real del curso: un monitor de sistema en Bash.

---

## 1. CONCEPTO: ¿por qué escribir scripts en vez de comandos sueltos?

Todo lo que hiciste hasta ahora fue **interactivo**: escribías un comando, veías el resultado, escribías el siguiente. Un **script** es una secuencia de comandos guardada en un archivo, que se ejecuta de punta a punta, de forma **repetible, automatizable y versionable** (podés guardarlo en git, como el resto de este curso).

**Por qué importa para un sysadmin/DevOps:** la diferencia entre alguien que "sabe usar la terminal" y alguien que "automatiza infraestructura" es, en gran parte, la capacidad de convertir una secuencia de comandos manuales en un script confiable que se puede ejecutar en cualquier servidor, cualquier cantidad de veces, con el mismo resultado.

---

## 2. CÓMO FUNCIONA: anatomía de un script

```bash
#!/usr/bin/env bash
# Comentario explicando qué hace el script

set -euo pipefail

echo "Hola, esto es un script"
```

- **`#!/usr/bin/env bash`** (shebang) → le dice al sistema con qué intérprete ejecutar el archivo. Sin esto, el sistema no sabría si es un script de bash, python, etc.
- **`set -euo pipefail`** → la línea más importante que vas a escribir en cada script profesional (sección 5).

```bash
chmod +x mi_script.sh    # darle permiso de ejecución (recordá el Módulo 04)
./mi_script.sh             # ejecutarlo
```

---

## 3. CÓMO FUNCIONA: variables, condicionales, bucles

### Variables

```bash
nombre="fabian"
echo "Hola, $nombre"
echo "Hola, ${nombre}"        # forma explícita, útil cuando hay ambigüedad (ej: "${nombre}_backup")

# Variables de solo lectura
readonly PI=3.14159

# Capturar la salida de un comando en una variable
fecha_actual=$(date +%Y-%m-%d)
echo "Hoy es $fecha_actual"
```

### Condicionales

```bash
if [[ -f /etc/fstab ]]; then
    echo "El archivo existe"
elif [[ -d /etc ]]; then
    echo "No es un archivo, pero /etc es un directorio"
else
    echo "Ninguna de las anteriores"
fi
```

Operadores de prueba comunes (dentro de `[[ ]]`):
```
-f archivo    → existe y es un archivo regular
-d carpeta     → existe y es un directorio
-x archivo      → existe y es ejecutable
-z "$var"        → la cadena está vacía
-n "$var"         → la cadena NO está vacía
"$a" == "$b"       → comparación de strings
"$a" -eq "$b"       → comparación numérica (igual)
"$a" -gt "$b"        → numérico (mayor que)
```

### Bucles

```bash
for i in 1 2 3 4 5; do
    echo "Número: $i"
done

for archivo in /etc/*.conf; do
    echo "Encontrado: $archivo"
done

contador=0
while [[ $contador -lt 5 ]]; do
    echo "Contador: $contador"
    ((contador++))
done
```

---

## 4. CÓMO FUNCIONA: funciones y argumentos

```bash
saludar() {
    local nombre="$1"          # "local" limita la variable a esta función (buena práctica)
    echo "Hola, $nombre"
}

saludar "Fabian"

# Argumentos del propio script (los que pasás al ejecutarlo)
echo "Nombre del script: $0"
echo "Primer argumento: $1"
echo "Todos los argumentos: $@"
echo "Cantidad de argumentos: $#"
```

```bash
./mi_script.sh hola mundo
# $0 = ./mi_script.sh, $1 = hola, $2 = mundo, $# = 2
```

---

## 5. CÓMO FUNCIONA: manejo de errores (la parte que separa un script amateur de uno profesional)

```bash
set -e           # el script se detiene INMEDIATAMENTE si cualquier comando falla (exit code distinto de 0)
set -u           # error si usás una variable que no fue definida (evita typos silenciosos)
set -o pipefail   # si CUALQUIER comando en un pipe falla, todo el pipe se considera fallido
                   # (recordá el Módulo 03: sin esto, un pipe "oculta" fallos intermedios)
```

**Por qué esto es crítico:** sin `set -e`, un script sigue ejecutando la línea 2 aunque la línea 1 haya fallado — pudiendo causar daño en cascada (ej: borrar algo asumiendo que un paso anterior tuvo éxito, cuando en realidad falló silenciosamente).

### Códigos de salida (exit codes)

```bash
comando
echo $?     # 0 = éxito, cualquier otro número = algún tipo de fallo
```

```bash
mi_funcion() {
    if [[ ! -f "$1" ]]; then
        echo "Error: archivo no encontrado" >&2   # los errores van a stderr (Módulo 03)
        return 1
    fi
    echo "Archivo válido"
    return 0
}
```

### `trap` — ejecutar algo al salir (limpieza garantizada)

```bash
archivo_temporal=$(mktemp)
trap 'rm -f "$archivo_temporal"' EXIT     # se ejecuta SIEMPRE al terminar el script, incluso si falla
```

---

## 6. Ahora sí: heredocs (por fin explicados)

En el Módulo 09 usaste `nano` en vez de esto porque todavía no lo habíamos visto. Ahora sí:

```bash
cat << 'EOF' > archivo.txt
Línea 1
Línea 2 con $variable_sin_expandir (las comillas en 'EOF' evitan que se interprete)
EOF

cat << EOF > archivo2.txt
Línea con $nombre SÍ se expande (sin comillas en EOF)
EOF
```

Un heredoc (`<<`) le dice al shell "todo lo que sigue, hasta que vuelva a aparecer esta palabra clave, es el contenido/entrada". Es la forma estándar de escribir archivos multilínea directo desde un script, sin abrir un editor.

---

## 7. EJEMPLO: Proyecto — Monitor de sistema en Bash

Vamos a construir el **Proyecto 6 de la guía**: un monitor de sistema simple.

```bash
mkdir -p ~/proyectos/monitor-sistema
nano ~/proyectos/monitor-sistema/monitor.sh
```

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Monitor del sistema — $(date) ==="
echo

echo "--- CPU y carga ---"
uptime

echo
echo "--- Memoria ---"
free -h

echo
echo "--- Disco ---"
df -h / /boot

echo
echo "--- Top 5 procesos por uso de memoria ---"
ps aux --sort=-%mem | head -n 6

echo
echo "--- Servicios systemd fallidos ---"
if systemctl --failed --no-legend | grep -q .; then
    systemctl --failed --no-legend
else
    echo "Ninguno. Todo en orden."
fi

echo
echo "=== Fin del reporte ==="
```

```bash
chmod +x ~/proyectos/monitor-sistema/monitor.sh
~/proyectos/monitor-sistema/monitor.sh
```

---

## 8. PRÁCTICA

1. Escribí y ejecutá el script `monitor.sh` completo de la sección 7.
2. Modificalo para que reciba un argumento opcional: si se pasa `--breve`, que solo muestre CPU y memoria (usando un `if` sobre `$1`).
3. Agregale `trap` para que imprima "Monitor finalizado" al salir, incluso si algo falla.
4. Escribí una función `chequear_espacio()` que reciba una ruta como argumento y devuelva un error (`return 1`) si el uso de disco de esa ruta supera el 90%.

---

## 9. ERROR INTENCIONAL

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Paso 1"
cat /archivo/que/no/existe
echo "Paso 2 (no debería llegar acá)"
```

---

## 10. DIAGNÓSTICO Y SOLUCIÓN

Al ejecutarlo, vas a ver que el script se **detiene después de "Paso 1"** y nunca llega a "Paso 2" — eso es exactamente `set -e` en acción: como `cat` falló (exit code distinto de 0), el script completo se detuvo automáticamente, en vez de seguir ejecutando comandos sobre un estado ya roto.

**Sin `set -e`** (probalo comentando esa línea), el script seguiría hasta el final igual, imprimiendo "Paso 2" a pesar del error — este es el comportamiento peligroso por defecto de bash que `set -e` corrige.

---

## Checklist de cierre del módulo

- [ ] Sé escribir un script con shebang, variables, condicionales y bucles.
- [ ] Sé escribir funciones con argumentos y valores de retorno.
- [ ] Entiendo y uso `set -euo pipefail` en todo script nuevo.
- [ ] Sé usar `trap` para limpieza garantizada.
- [ ] Entiendo heredocs y cuándo usarlos.
- [ ] Completé el proyecto del monitor de sistema y sus extensiones de la práctica.

---

**Próximo módulo:** 18 — Git.
