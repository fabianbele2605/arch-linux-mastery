# Módulo 24 — Contenedores (Docker/Podman)

**Fase V — Infrastructure & Advanced Systems**

> Ya tenés Docker instalado y corriendo desde hace varios módulos (lo detectamos por primera vez en el Módulo 04, y lo viste activo en `htop`, `ip addr`, `ps aux` repetidas veces). Este módulo formaliza lo que ya venía funcionando en segundo plano.

---

## Objetivos del módulo

- Entender qué es realmente un contenedor (y por qué **no** es una VM, aunque se parezcan de afuera).
- Entender `namespaces` y `cgroups` — los mecanismos del kernel que hacen posible los contenedores.
- Dominar el ciclo de vida de contenedores con Docker: `run`, `ps`, `exec`, `logs`, `stop`, `rm`.
- Construir tu propia imagen con un `Dockerfile`.
- Orquestar múltiples contenedores con `docker-compose`.

---

## 1. CONCEPTO: contenedor vs. máquina virtual — la diferencia real

Ya estudiaste virtualización completa en el Módulo 23: cada VM tiene su **propio kernel**, emulado o corriendo sobre KVM, con su propia copia completa del sistema operativo.

Un **contenedor NO tiene su propio kernel**. Todos los contenedores en tu sistema **comparten el kernel del host** (el mismo que corre tu Arch Linux). Lo que aísla a un contenedor no es un kernel separado, sino dos mecanismos del kernel Linux que ya tocaste indirectamente:

```
VM:         Hardware → Hipervisor → Kernel invitado → Apps
Contenedor: Hardware → Kernel del host → Namespaces/cgroups → Apps
```

**Por qué importa esta diferencia:** los contenedores arrancan en milisegundos (no hay que bootear un kernel completo, como viste en el Módulo 10), pesan mucho menos (no cargan un SO entero), pero **no podés correr un contenedor de un kernel distinto al del host** (por ejemplo, no podés correr un contenedor "Windows" sobre un host Linux — eso sí lo permite una VM completa).

---

## 2. CONCEPTO: namespaces y cgroups — la magia real detrás de Docker

### Namespaces — aislamiento de "qué ve" un proceso

Un namespace hace que un proceso **crea** que está solo en el sistema, aunque no lo esté. Tipos principales:

| Namespace | Aísla |
|---|---|
| PID | Los PIDs — un proceso dentro del contenedor puede verse como PID 1, aunque en el host tenga otro PID real |
| NET | La red — el contenedor tiene su propia interfaz de red, tabla de rutas, puertos |
| MNT | Los puntos de montaje — el contenedor ve su propio filesystem raíz |
| UTS | El hostname — el contenedor puede tener su propio nombre, distinto del host |

### cgroups (control groups) — límites de recursos

Mientras los namespaces controlan **qué ve** un proceso, los `cgroups` controlan **cuánto puede usar** (CPU, memoria, I/O de disco) — evitando que un contenedor acapare todos los recursos del host.

```bash
# Ver los cgroups de un contenedor corriendo (una vez que tengas uno activo)
cat /sys/fs/cgroup/system.slice/docker-*.scope/memory.max 2>/dev/null
```

**Conexión con el Módulo 22:** tanto namespaces como cgroups son funcionalidad del kernel — Docker no "inventa" el aislamiento, es una herramienta que **orquesta** estas primitivas del kernel Linux (que ya estaban ahí, usadas para otras cosas, desde mucho antes de que Docker existiera).

---

## 3. HERRAMIENTA: ciclo de vida de contenedores con Docker

```bash
docker ps                    # contenedores corriendo ahora
docker ps -a                   # todos, incluidos los detenidos

docker run hello-world           # descarga (si hace falta) y corre un contenedor de prueba
docker run -d --name mi-nginx -p 8080:80 nginx    # -d = detached (background), -p = mapeo de puerto

docker exec -it mi-nginx bash       # abrir una shell DENTRO del contenedor corriendo
docker logs mi-nginx                  # ver la salida/logs del contenedor
docker stop mi-nginx                    # detener (SIGTERM, recordá el Módulo 05)
docker rm mi-nginx                        # eliminar el contenedor (debe estar detenido)

docker images                              # imágenes descargadas localmente
docker rmi nginx                             # eliminar una imagen
```

**Conexión directa con el Módulo 05:** `docker exec -it` te mete dentro del contenedor con una shell interactiva — pero recordá que ese contenedor **es solo procesos Linux normales**, corriendo con namespaces aplicados. Si hacés `ps aux` desde el host (fuera del contenedor), vas a poder verlos igual, con otro PID.

---

## 4. EJEMPLO: probar lo que ya tenés corriendo

```bash
docker ps -a
docker images
```

Como Docker ya viene funcionando en tu sistema, probablemente tengas contenedores o imágenes de sesiones anteriores — este es un buen momento para auditar qué hay.

---

## 5. CÓMO FUNCIONA: construir tu propia imagen con `Dockerfile`

```bash
mkdir ~/proyectos/mi-contenedor
cd ~/proyectos/mi-contenedor
nano Dockerfile
```

```dockerfile
FROM archlinux:latest

RUN pacman -Sy --noconfirm python

COPY app.py /app.py

CMD ["python", "/app.py"]
```

```bash
nano app.py
```

```python
print("Hola desde un contenedor Arch Linux, construido por mi mismo")
```

```bash
docker build -t mi-imagen-arch .
docker run mi-imagen-arch
```

**Qué pasó:** `docker build` ejecutó cada instrucción del `Dockerfile` como una "capa" (layer) — cada `RUN`/`COPY` genera una capa nueva, cacheada, para que reconstruir sea rápido si solo cambiaste las últimas líneas.

---

## 6. HERRAMIENTA: orquestar con `docker-compose`

Para el Proyecto 11 de la guía (servidor de contenedores), vas a necesitar coordinar varios contenedores juntos (por ejemplo, una app + su base de datos):

```bash
sudo pacman -S docker-compose
nano docker-compose.yml
```

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ejemplo
```

```bash
docker-compose up -d       # levanta ambos servicios en background
docker-compose ps            # ver el estado
docker-compose down            # apagar y limpiar todo
```

---

## 7. PRÁCTICA

1. `docker ps -a` y `docker images` — auditá qué tenías corriendo/descargado antes de este módulo.
2. Corré `docker run -d --name mi-nginx -p 8080:80 nginx`, y confirmá desde tu VM: `curl localhost:8080` debería devolver el HTML de bienvenida de nginx.
3. Entrá al contenedor con `docker exec -it mi-nginx bash`, y desde adentro corré `hostname` y `ps aux` — comparalo con lo que ves desde afuera.
4. Construí tu propia imagen con el `Dockerfile` de la sección 5.
5. Armá el `docker-compose.yml` de la sección 6 y levantalo con `docker-compose up -d`.

---

## 8. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
docker rm mi-nginx    # sin haberlo detenido primero
```

**Diagnóstico:** Docker se niega con `Error: You cannot remove a running container` — mismo principio de protección que venimos viendo en todo el curso (systemd, LVM, módulos de kernel): no dejar destruir algo activo sin confirmación explícita.

**Solución:**
```bash
docker stop mi-nginx
docker rm mi-nginx
```

---

## Checklist de cierre del módulo

- [ ] Entiendo por qué un contenedor no es una VM (comparte el kernel del host).
- [ ] Entiendo namespaces (qué ve un proceso) y cgroups (cuánto puede usar).
- [ ] Domino el ciclo de vida: `run`, `ps`, `exec`, `logs`, `stop`, `rm`.
- [ ] Construí mi propia imagen con un `Dockerfile`.
- [ ] Orquesté múltiples servicios con `docker-compose`.

---

## Evidencias

**01 — `docker ps -a`: auditoría de contenedores previos**
El sistema ya tenía 9 contenedores detenidos de un proyecto anterior ("entrevista"): una API, Postgres, Redis, y un stack completo de observabilidad (Grafana, Prometheus, Loki, Tempo, Alertmanager, Promtail).

![docker ps -a: auditoría previa](evidencias/01-docker-ps-auditoria-previa.png)

**02 — `docker images`: auditoría de imágenes**
11 imágenes descargadas de ese proyecto, ~2.2 GB en total.

![docker images: auditoría](evidencias/02-docker-images-auditoria.png)

**03 — `nginx` corrido y `curl` exitoso**
Contenedor de nginx levantado con mapeo de puerto (`8080:80`); `curl localhost:8080` devolvió la página de bienvenida real.

![nginx run y curl exitoso](evidencias/03-nginx-run-y-curl-exitoso.png)

**04 — `docker exec`: `hostname` distinto, `ps` no disponible**
Dentro del contenedor, `hostname` coincide con el Container ID (namespace UTS en acción); `ps` no está instalado en la imagen minimalista de nginx.

![exec hostname y ps not found](evidencias/04-exec-hostname-ps-not-found.png)

**05 — Desde el host: los procesos de nginx SÍ son visibles**
`ps aux | grep nginx` desde el host muestra el proceso master y 4 workers con PIDs reales — prueba de que el namespace PID aísla la *percepción*, no la realidad del proceso.

![ps aux desde el host ve los procesos de nginx](evidencias/05-ps-aux-host-ve-procesos-nginx.png)

**06 — `Dockerfile` y `app.py` propios**
Imagen personalizada basada en `archlinux:latest`, con Python instalado y un script propio copiado adentro.

![Dockerfile y app.py](evidencias/06-dockerfile-y-app-py.png)

**07 — Error: falta el punto de contexto de build**
`docker build -t mi-imagen-arch` sin el `.` final falla porque no se especificó el contexto (carpeta) del build.

![Error: falta el punto de contexto](evidencias/07-error-falta-punto-contexto-build.png)

**08 — DNS timeout dentro del contenedor**
`pacman -Sy` dentro del `Dockerfile` falló resolviendo los mirrors, incluso con buena conexión en el host — primera señal de un problema específico de red de contenedores.

![DNS timeout dentro del contenedor](evidencias/08-dns-timeout-dentro-contenedor.png)

**09 — `resolv.conf`: host vs. contenedor**
El contenedor heredó `nameserver 10.0.2.3` del host — un DNS que VirtualBox expone solo para la interfaz principal de la VM, no fácilmente alcanzable desde el namespace de red de un contenedor.

![resolv.conf host vs contenedor](evidencias/09-resolv-conf-host-vs-contenedor.png)

**10 — `daemon.json`: DNS público configurado**
Se configuró Docker para usar `8.8.8.8`/`1.1.1.1` en vez del DNS heredado del host, confirmado en el `resolv.conf` del contenedor tras reiniciar el daemon.

![daemon.json con DNS público](evidencias/10-daemon-json-dns-publico.png)

**11 — `ping` con 100% de pérdida: el problema es más profundo que DNS**
Ni siquiera una IP directa (`8.8.8.8`, sin DNS de por medio) era alcanzable desde el contenedor — descartó el DNS como causa única y apuntó a un problema de reenvío de tráfico.

![ping 100% de pérdida](evidencias/11-ping-100-perdida-mas-alla-de-dns.png)

**12 — Hallazgo: `chain forward { policy drop; }` vacía**
La causa raíz real: el firewall configurado en el Módulo 14 tenía la cadena `forward` completamente vacía con política `drop`, bloqueando todo el tráfico reenviado del bridge de Docker hacia internet.

![Hallazgo: forward chain en policy drop](evidencias/12-hallazgo-forward-chain-policy-drop.png)

**13 — Fix aplicado: `ping` exitoso**
Tras agregar reglas de `accept` para `docker0` y conexiones establecidas, el `ping` desde el contenedor funcionó con 0% de pérdida.

![Fix aplicado: ping exitoso](evidencias/13-fix-forward-chain-ping-exitoso.png)

**14 — `/etc/nftables.conf` con el fix persistido**
El arreglo se agregó también al archivo de configuración permanente, validado con `nft -c -f` antes de aplicar.

![nftables.conf con el fix persistido](evidencias/14-nftables-conf-persistido.png)

**15 — `docker build` exitoso**
Con el firewall corregido, la construcción de la imagen completó sin errores de red.

![docker build exitoso](evidencias/15-docker-build-exitoso.png)

**16 — `docker run`: mensaje final**
La imagen propia corrió correctamente, imprimiendo el mensaje esperado.

![docker run mensaje final](evidencias/16-docker-run-mensaje-final.png)

**17 — `docker-compose.yml`: error de tabs**
El archivo YAML tenía tabs reales en la indentación (efecto colateral de haber desactivado `tabstospaces` para el `Makefile` del Módulo 22) — YAML no permite tabs en absoluto.

![docker-compose.yml: error de tabs](evidencias/17-docker-compose-yml-tabs-error.png)

**18 — `docker-compose.yml`: espacio faltante**
Tras arreglar los tabs, apareció un segundo error de sintaxis: `image:postgres:16` sin espacio después de los dos puntos.

![docker-compose.yml: espacio faltante](evidencias/18-docker-compose-yml-espacio-faltante.png)

**19 — `docker-compose up -d` exitoso**
Ambos servicios (`web` con nginx, `db` con Postgres) levantados y corriendo correctamente, con su propia red dedicada.

![docker-compose up exitoso](evidencias/19-docker-compose-up-exitoso.png)

---

**Próximo módulo:** 25 — Servidores web (Nginx/Caddy/TLS).
