# Módulo 21 — Rust para sistemas

**Fase IV — Development & Automation**

Con este módulo cerramos la Fase IV.

---

## Objetivos del módulo

- Entender qué problema de C resuelve Rust, y por qué crece tanto en programación de sistemas.
- Usar `cargo` (el gestor de paquetes/build de Rust) en vez de compilar a mano.
- Entender ownership (propiedad) y borrowing (préstamo) — el mecanismo central de Rust.
- Manejar errores con `Result` y `Option`, sin excepciones ni punteros nulos.
- Reescribir el problema del Módulo 20 (el segfault) en Rust, y ver que **no compila** — a propósito.

---

## 1. CONCEPTO: ¿qué problema de C resuelve Rust?

En el Módulo 20 provocaste un segfault desreferenciando un puntero `NULL`. Ese tipo de error es **la fuente histórica más común de vulnerabilidades de seguridad graves** en software de sistemas (buffer overflows, use-after-free, null pointer dereference) — errores de memoria que C te permite cometer sin avisarte en tiempo de compilación.

**Rust resuelve esto en el compilador, no en tiempo de ejecución.** Su sistema de ownership hace que la mayoría de esos errores de memoria **ni siquiera compilen** — el programa nunca llega a ejecutarse con el bug. Por eso Rust ganó tanta adopción en programación de sistemas: te da el control de bajo nivel de C, sin el riesgo de memoria, y sin necesitar un recolector de basura (garbage collector) que agregue overhead como en Python o Java.

---

## 2. HERRAMIENTA: `cargo` — el gestor de proyectos de Rust

```bash
sudo pacman -S rust

cargo new hola_rust
cd hola_rust
cat src/main.rs
```

`cargo new` crea toda la estructura de un proyecto (código fuente, control de dependencias, configuración de build) automáticamente — mucho más que el `gcc archivo.c -o binario` manual del Módulo 20.

```bash
cargo run       # compila Y ejecuta en un solo paso
cargo build       # solo compila (el binario queda en target/debug/)
cargo build --release   # compilación optimizada para producción
```

---

## 3. CONCEPTO: ownership (propiedad)

### La regla central de Rust

Cada valor en Rust tiene **un único dueño** en cada momento. Cuando ese dueño "sale de scope" (termina la función/bloque donde vive), el valor se libera automáticamente — sin `free()` manual, y sin garbage collector corriendo en segundo plano.

```rust
fn main() {
    let s1 = String::from("hola");
    let s2 = s1;             // la propiedad de s1 se MUEVE a s2

    println!("{}", s2);        // esto funciona
    println!("{}", s1);         // ¡ERROR DE COMPILACIÓN! s1 ya no es dueño de nada
}
```

Esto se ve raro viniendo de otros lenguajes, pero es exactamente el mecanismo que previene los bugs de memoria del Módulo 20: **el compilador rastrea, en todo momento, quién es responsable de cada dato**, y no te deja usar algo después de que dejó de ser válido.

### Borrowing (préstamo) — usar sin tomar posesión

```rust
fn calcular_largo(s: &String) -> usize {   // "&" = préstamo, no toma posesión
    s.len()
}

fn main() {
    let s1 = String::from("hola");
    let largo = calcular_largo(&s1);        // le "prestamos" s1 a la función
    println!("{} tiene {} caracteres", s1, largo);   // s1 sigue siendo válida acá
}
```

---

## 4. CÓMO FUNCIONA: `Option` y `Result` — sin `NULL`, sin excepciones sin control

### El problema que resuelven

En C, un puntero puede ser `NULL` sin ningún aviso — tu segfault del Módulo 20 nació exactamente de eso. Rust **no tiene `NULL`**. En su lugar, cualquier valor que "puede no existir" se envuelve explícitamente en `Option`:

```rust
fn buscar_usuario(id: u32) -> Option<String> {
    if id == 1 {
        Some(String::from("fabian"))
    } else {
        None
    }
}

fn main() {
    match buscar_usuario(1) {
        Some(nombre) => println!("Usuario encontrado: {}", nombre),
        None => println!("Usuario no encontrado"),
    }
}
```

El compilador **te obliga** a manejar ambos casos (`Some` y `None`) — no podés "olvidarte" de chequear si algo existe, como sí pasa fácilmente en C con un puntero.

### `Result` — para operaciones que pueden fallar

```rust
use std::fs::File;

fn main() {
    let resultado = File::open("/etc/hostname");

    match resultado {
        Ok(archivo) => println!("Archivo abierto: {:?}", archivo),
        Err(error) => println!("Error al abrir: {}", error),
    }
}
```

Igual que `Option`, `Result` (con sus variantes `Ok`/`Err`) obliga a manejar explícitamente el caso de error — el equivalente de bash `set -e` (Módulo 17) o Python `try/except` (Módulo 19), pero verificado por el compilador antes de que el programa corra.

---

## 5. EJEMPLO: el segfault del Módulo 20, en Rust

Intentemos reproducir el mismo error:

```bash
cargo new segfault_rust
cd segfault_rust
nano src/main.rs
```

```rust
fn main() {
    let puntero: Option<&i32> = None;
    println!("{}", puntero.unwrap());   // .unwrap() sobre None SÍ puede fallar en runtime
}
```

```bash
cargo run
```

**Resultado:** esto sí compila (porque `Option` es un tipo válido), pero **falla en runtime** con un mensaje claro:
```
thread 'main' panicked at 'called `Option::unwrap()` on a `None` value'
```

**La diferencia clave con C:** no es un segfault silencioso que el kernel tiene que matar — es un "panic" controlado, con un mensaje explícito señalando exactamente qué pasó. Rust te fuerza a decidir conscientemente cómo manejar el caso `None` (con `.unwrap()` estás diciendo "estoy seguro de que nunca va a ser None, y si me equivoco, quiero un error claro").

### La forma correcta (sin arriesgar el panic)

```rust
fn main() {
    let puntero: Option<&i32> = None;
    match puntero {
        Some(valor) => println!("Valor: {}", valor),
        None => println!("No hay valor, todo bien"),
    }
}
```

---

## 6. PRÁCTICA

1. Instalá Rust, creá el proyecto `hola_rust`, corré `cargo run`.
2. Reproducí el ejemplo de ownership de la sección 3 — confirmá que el compilador rechaza usar `s1` después de moverla a `s2`. Leé el mensaje de error completo (Rust da mensajes muy detallados, a menudo con sugerencias).
3. Escribí la función `buscar_usuario` con `Option`, probando ambos casos (`Some` y `None`).
4. Reproducí el ejemplo de la sección 5 con `.unwrap()` sobre `None`, y después corregilo con `match` para que no crashee.

---

## 7. ERROR INTENCIONAL / DIAGNÓSTICO

```rust
fn main() {
    let s1 = String::from("dato importante");
    let s2 = s1;
    println!("{}", s1);
}
```

## 8. SOLUCIÓN

El compilador va a rechazar esto con un error de tipo `borrow of moved value`, señalando exactamente la línea y sugiriendo usar `.clone()` si realmente necesitás dos copias independientes:

```rust
let s2 = s1.clone();   // ahora hay DOS strings independientes, cada una con su propio dueño
```

**Esto es la esencia de por qué Rust es más seguro:** el error que en C hubiera sido un bug silencioso en producción (o ni siquiera un bug, solo comportamiento indefinido), en Rust es un error de compilación que **nunca llega a producción**.

---

## Checklist de cierre del módulo (y de la Fase IV completa)

- [ ] Entiendo qué problema de memoria de C resuelve el ownership de Rust.
- [ ] Sé usar `cargo new`, `cargo run`, `cargo build`.
- [ ] Entiendo ownership y borrowing (`&`).
- [ ] Sé usar `Option` y `Result` para manejar ausencia de valor y errores, sin `NULL`.
- [ ] Reproduje el error de moved value y lo corregí con `.clone()`.

---

## Cierre de Fase IV — Development & Automation

Con este módulo termina la Fase IV completa: Bash, Git, Python, C y Rust. Recorriste el espectro completo de automatización de sistemas — desde scripts que orquestan comandos (Bash) hasta lenguajes de sistemas con y sin garantías de memoria en tiempo de compilación (C y Rust). Ya tenés las herramientas de programación necesarias para la Fase V, donde vas a construir infraestructura real: kernel, virtualización, contenedores, servidores, DevOps y seguridad.

---

**Próximo módulo:** 22 — Kernel Linux (inicio de la Fase V — Infrastructure & Advanced Systems).
