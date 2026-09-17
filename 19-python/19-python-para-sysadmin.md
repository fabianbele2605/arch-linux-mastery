# Módulo 19 — Python para sysadmin

**Fase IV — Development & Automation**

---

## Objetivos del módulo

- Entender cuándo usar Python en vez de Bash (y viceversa).
- Manejar archivos, `subprocess`, y estructuras de datos para automatización de sistemas.
- Usar entornos virtuales (`venv`) y `pip` correctamente.
- Procesar argumentos de línea de comandos con `argparse`.
- Construir el Proyecto 7 de la guía: un analizador de logs en Python.

---

## 1. CONCEPTO: ¿por qué Python además de Bash?

Bash (Módulo 17) es excelente para **encadenar comandos y automatizar tareas del sistema operativo**. Pero se vuelve incómodo cuando necesitás:
- Estructuras de datos complejas (diccionarios, listas anidadas).
- Parsing de texto estructurado (JSON, CSV) de forma robusta.
- Lógica de programación más elaborada (funciones con múltiples valores de retorno, clases, manejo de excepciones granular).

**Regla práctica de la industria:** scripts cortos que orquestan comandos del sistema → Bash. Lógica de negocio, procesamiento de datos, o herramientas que van a crecer y mantenerse en el tiempo → Python. No es una jerarquía de "mejor/peor", son herramientas para problemas distintos — vas a usar ambos constantemente en DevOps real.

---

## 2. CÓMO FUNCIONA: entornos virtuales y pip

### El problema que resuelven los entornos virtuales

Si instalás paquetes de Python globalmente (`pip install algo`), todos tus proyectos comparten las mismas versiones — un proyecto que necesita `requests==2.0` y otro que necesita `requests==3.0` no pueden convivir. Un **entorno virtual** crea una instalación aislada de Python + paquetes, por proyecto.

```bash
sudo pacman -S python python-pip

python -m venv ~/proyectos/analizador-logs/venv
source ~/proyectos/analizador-logs/venv/bin/activate   # activarlo (verás "(venv)" en el prompt)

pip install requests    # se instala SOLO dentro de este entorno
pip freeze > requirements.txt   # guardar las dependencias exactas usadas

deactivate                # salir del entorno virtual
```

**Nota Arch-específica:** Arch aplica PEP 668 (entornos "externally managed") — `pip install` global directo puede rechazarse a propósito, empujándote a usar `venv` siempre. Esto es una decisión de seguridad/orden, no un error.

---

## 3. CÓMO FUNCIONA: archivos y `subprocess`

```python
# Leer un archivo línea por línea (forma eficiente, no carga todo en memoria)
with open("/var/log/mi_app.log") as f:
    for linea in f:
        print(linea.strip())

# Escribir un archivo
with open("reporte.txt", "w") as f:
    f.write("Reporte generado\n")
```

El bloque `with` garantiza que el archivo se cierre correctamente incluso si ocurre un error — es el equivalente conceptual al `trap` de bash (Módulo 17), pero integrado al lenguaje.

```python
import subprocess

resultado = subprocess.run(["systemctl", "is-active", "sshd"], capture_output=True, text=True)
print(resultado.stdout.strip())      # "active" o "inactive"
print(resultado.returncode)            # 0 si tuvo éxito, otro número si falló
```

**Por qué `subprocess` en vez de un simple "ejecutar comando":** te da control total — capturás stdout/stderr por separado (recordá el Módulo 03), el código de salida, y podés manejar errores con `try/except` en vez de que el script entero se caiga.

---

## 4. CÓMO FUNCIONA: manejo de errores con `try/except`

```python
try:
    with open("/archivo/que/no/existe") as f:
        contenido = f.read()
except FileNotFoundError:
    print("El archivo no existe, usando valores por defecto")
except PermissionError:
    print("No tenés permisos para leer ese archivo")
finally:
    print("Esto se ejecuta siempre, haya error o no")
```

Es el equivalente de `set -e` + manejo explícito de bash, pero con la ventaja de poder reaccionar **distinto** según el tipo exacto de error.

---

## 5. HERRAMIENTA: `argparse` — argumentos de línea de comandos

```python
import argparse

parser = argparse.ArgumentParser(description="Analizador de logs")
parser.add_argument("archivo", help="Ruta del archivo de log a analizar")
parser.add_argument("--nivel", default="ERROR", help="Nivel mínimo a reportar")
parser.add_argument("-v", "--verbose", action="store_true", help="Mostrar detalle completo")

args = parser.parse_args()
print(args.archivo, args.nivel, args.verbose)
```

```bash
python analizador.py /var/log/mi_app.log --nivel WARNING -v
```

---

## 6. EJEMPLO: Proyecto — Analizador de logs en Python

Vamos a construir el **Proyecto 7 de la guía**.

```bash
mkdir -p ~/proyectos/analizador-logs
python -m venv ~/proyectos/analizador-logs/venv
source ~/proyectos/analizador-logs/venv/bin/activate
nano ~/proyectos/analizador-logs/analizador.py
```

```python
#!/usr/bin/env python3
import argparse
import re
from collections import Counter

def analizar(ruta, nivel_minimo):
    niveles_validos = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    indice_minimo = niveles_validos.index(nivel_minimo)

    contador_niveles = Counter()
    lineas_relevantes = []

    patron = re.compile(r"\b(DEBUG|INFO|WARNING|ERROR|CRITICAL)\b")

    try:
        with open(ruta) as f:
            for numero_linea, linea in enumerate(f, start=1):
                match = patron.search(linea)
                if not match:
                    continue
                nivel = match.group(1)
                contador_niveles[nivel] += 1

                if niveles_validos.index(nivel) >= indice_minimo:
                    lineas_relevantes.append((numero_linea, nivel, linea.strip()))
    except FileNotFoundError:
        print(f"Error: no se encontró el archivo '{ruta}'")
        return

    print(f"=== Resumen de niveles en '{ruta}' ===")
    for nivel in niveles_validos:
        print(f"  {nivel}: {contador_niveles[nivel]}")

    print(f"\n=== Líneas con nivel >= {nivel_minimo} ({len(lineas_relevantes)}) ===")
    for numero, nivel, texto in lineas_relevantes[:20]:
        print(f"  [{numero}] {texto}")

    if len(lineas_relevantes) > 20:
        print(f"  ... y {len(lineas_relevantes) - 20} más")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analizador simple de logs")
    parser.add_argument("archivo", help="Ruta del archivo de log")
    parser.add_argument("--nivel", default="WARNING",
                         choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
                         help="Nivel mínimo a reportar (default: WARNING)")
    args = parser.parse_args()

    analizar(args.archivo, args.nivel)
```

### Generar un log de prueba para analizarlo

```bash
cat > /tmp/prueba.log << 'EOF'
2026-09-16 10:00:01 INFO Servicio iniciado correctamente
2026-09-16 10:00:05 DEBUG Cargando configuración
2026-09-16 10:01:12 WARNING Uso de memoria alto: 85%
2026-09-16 10:02:30 ERROR No se pudo conectar a la base de datos
2026-09-16 10:02:31 ERROR Reintentando conexión
2026-09-16 10:02:45 INFO Conexión restablecida
2026-09-16 10:05:00 CRITICAL Disco casi lleno: 98%
EOF

python ~/proyectos/analizador-logs/analizador.py /tmp/prueba.log --nivel ERROR
```

---

## 7. PRÁCTICA

1. Creá el entorno virtual, el script, y el log de prueba de la sección 6, y ejecutalo.
2. Probá con distintos `--nivel` (`DEBUG`, `WARNING`, `CRITICAL`) y confirmá que el filtrado cambia correctamente.
3. Corré el analizador contra un log real de tu sistema: `sudo python analizador.py /var/log/pacman.log --nivel INFO` (pacman también registra sus operaciones ahí, aunque no siga el mismo formato exacto — observá qué pasa cuando el patrón no matchea ninguna línea).
4. Agregale al script una opción `--salida archivo.json` que guarde el resumen de conteo por nivel en formato JSON (pista: módulo `json` de Python, `json.dump()`).

---

## 8. ERROR INTENCIONAL

```python
def analizar(ruta, nivel_minimo):
    indice_minimo = niveles_validos.index(nivel_minimo)   # "niveles_validos" no definida acá arriba
```

Ejecutalo con un nivel que no coincida con la lista, o directamente rompé la indentación de una línea del script a propósito.

---

## 9. DIAGNÓSTICO Y SOLUCIÓN

Python, a diferencia de bash, te da un **traceback completo**: el archivo, la línea exacta, y el tipo de excepción (`NameError`, `IndentationError`, `ValueError`). Leer el traceback de abajo hacia arriba (el error real está en la última línea, el "camino" para llegar ahí arriba) es una habilidad central para debuggear Python — mucho más informativo que muchos errores de bash.

---

## Nota real del curso: cuando escribir código a mano (sin copiar/pegar) es el verdadero desafío

Como la VM no tiene portapapeles compartido con el host, todo el script se tipeó a mano dentro de la terminal. Esto generó una sesión de debugging real y valiosa, con errores genuinos de Python (no simulados):

- `TabError: inconsistent use of tabs and spaces` — mezcla de tabs y espacios al tipear en `nano`.
- `IndentationError: unindent does not match any outer indentation level` — niveles de indentación inconsistentes.
- Una línea de `argparse` completa perdida al tipear.
- Un typo `add:argument` en vez de `add_argument`.
- `default=WARNING` sin comillas (intentaba usar una variable inexistente en vez de un string).
- `NameError` por una variable con un nombre ligeramente distinto (`niveles_valido` vs `niveles_validos`) — Python sugirió la corrección automáticamente (`Did you mean: ...?`), una función real del intérprete que vale la pena conocer.

**Lección clave:** leer el traceback completo, de abajo hacia arriba, fue lo que permitió resolver cada error en segundos en vez de minutos. Quedan dos bugs menores de lógica sin resolver (conteo de `WARNING` incorrecto, y un mensaje de "líneas restantes" con número negativo) — documentados aquí como deuda técnica real, no como algo "mal cerrado": en el mundo real, no todo bug se resuelve en la misma sesión, y saber cuándo seguir adelante es parte de la habilidad.

---

## Checklist de cierre del módulo

- [ ] Entiendo cuándo elegir Python sobre Bash y viceversa.
- [ ] Sé crear y usar un entorno virtual con `venv` y `pip`.
- [ ] Sé leer/escribir archivos y usar `subprocess` para ejecutar comandos del sistema.
- [ ] Sé manejar errores con `try/except/finally`.
- [ ] Sé procesar argumentos con `argparse`.
- [ ] Completé el Proyecto 7 (analizador de logs) y sus extensiones de la práctica.

---

**Próximo módulo:** 20 — C para entender Linux.
