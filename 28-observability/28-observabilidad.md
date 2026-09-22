# Módulo 28 — Observabilidad (Prometheus/Grafana)

**Fase V — Infrastructure & Advanced Systems**

> Recordá el Módulo 24: al auditar Docker, encontraste un stack completo de observabilidad (`entrevista-prometheus-1`, `entrevista-grafana-1`, `entrevista-loki-1`, `entrevista-tempo-1`, `entrevista-alertmanager-1`, `entrevista-promtail-1`) de un proyecto anterior, detenido pero completo. Este módulo lo va a usar directamente en vez de armar todo desde cero.

---

## Objetivos del módulo

- Entender los 3 pilares de la observabilidad: métricas, logs y trazas.
- Entender el modelo de Prometheus (pull-based) y por qué es distinto a otros sistemas de monitoreo.
- Levantar y explorar tu stack existente de Prometheus + Grafana.
- Crear un dashboard real en Grafana con datos de tu propio sistema.
- Configurar una alerta básica.

---

## 1. CONCEPTO: los 3 pilares de la observabilidad

| Pilar | Qué responde | Herramienta en tu stack |
|---|---|---|
| **Métricas** | ¿Cuánto? (CPU, memoria, requests/seg, en el tiempo) | Prometheus |
| **Logs** | ¿Qué pasó exactamente, en texto? | Loki |
| **Trazas** | ¿Por dónde viajó una request específica, entre qué servicios? | Tempo |

**Por qué separarlos:** cada tipo de dato tiene una forma óptima distinta de almacenarse y consultarse. Las métricas son series numéricas en el tiempo (eficientes de comprimir y graficar); los logs son texto libre (necesitan búsqueda de texto); las trazas son árboles de spans relacionados (necesitan reconstruir el camino de una request). Intentar meter los tres en una sola herramienta genérica sería ineficiente para todos.

**Conexión con módulos anteriores:** ya usaste la versión "manual" de cada uno de estos pilares — `journalctl` (Módulo 15) es logs, `ps aux`/`top` (Módulo 05) es métricas puntuales sin historial, y `strace`/`gdb` (Módulo 20) es rastrear la ejecución de un proceso. Prometheus/Loki/Tempo automatizan y **persisten en el tiempo** lo que antes mirabas puntualmente.

---

## 2. CONCEPTO: el modelo pull de Prometheus

**Por qué es distinto:** muchos sistemas de monitoreo antiguos son "push" — cada servidor envía activamente sus métricas a un servidor central. Prometheus es **pull**: él mismo se conecta periódicamente a cada servicio (un endpoint `/metrics`) y **recolecta** ("scrapea") los datos.

**Ventajas del modelo pull:**
- Prometheus sabe inmediatamente si un servicio dejó de responder (falla el scrape) — eso **es** una señal de monitoreo en sí misma.
- Los servicios no necesitan saber nada sobre dónde está el servidor de monitoreo — solo exponen `/metrics`, y Prometheus decide cuándo y con qué frecuencia consultarlos.

---

## 3. HERRAMIENTA: levantar tu stack existente

```bash
docker ps -a | grep entrevista
```

Si el proyecto tiene su propio `docker-compose.yml` en algún lado, ubicalo y levantalo:

```bash
find / -iname "docker-compose*.yml" 2>/dev/null | xargs grep -l "grafana" 2>/dev/null
```

Si lo encontrás:
```bash
cd <carpeta-del-proyecto>
docker-compose up -d
docker-compose ps
```

Si no encontrás el `docker-compose.yml` original (puede haberse borrado, dejando solo los contenedores), podés arrancar los contenedores individuales directamente:

```bash
docker start entrevista-prometheus-1 entrevista-grafana-1
docker ps
```

---

## 4. EJEMPLO: explorar Prometheus

```bash
docker port entrevista-prometheus-1    # confirmar en qué puerto del host quedó expuesto
curl localhost:<puerto>/api/v1/targets   # ver qué servicios está scrapeando actualmente
```

Abrí en un navegador (si tenés GUI en la VM) o seguí por `curl`:
```bash
curl -s "localhost:<puerto>/api/v1/query?query=up" | python3 -m json.tool
```

La métrica `up` es la más básica que existe en Prometheus: `1` si el servicio scrapeado respondió, `0` si no — el equivalente directo de "¿está vivo?" para cada target configurado.

---

## 5. EJEMPLO: Grafana — dashboards reales

```bash
docker port entrevista-grafana-1
```

Accedé a Grafana (por navegador si tu VM tiene entorno gráfico, o documentando la API vía `curl` si no):

```bash
curl -u admin:admin localhost:<puerto-grafana>/api/health
```

Dentro de Grafana (usuario/contraseña por defecto suelen ser `admin`/`admin`, a menos que el proyecto original los haya cambiado):

1. **Configuración → Data sources** — confirmá que Prometheus y Loki ya están conectados como fuentes de datos (probablemente preconfigurados en el proyecto original).
2. **Dashboards → New Dashboard** — creá un panel nuevo con una query simple: `up` (mostrará qué servicios están arriba/abajo en el tiempo).
3. Agregá otro panel con `rate(node_cpu_seconds_total[5m])` si tenés `node_exporter` corriendo, o cualquier métrica disponible en tu stack.

---

## 6. CÓMO FUNCIONA: alertas básicas

En Prometheus (o Alertmanager, ya en tu stack), una regla de alerta se define declarativamente:

```yaml
groups:
  - name: alertas-basicas
    rules:
      - alert: ServicioCaido
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "El servicio {{ $labels.instance }} está caído"
```

**Cómo funciona:** Prometheus evalúa la expresión `up == 0` continuamente; si se cumple durante al menos 1 minuto seguido (`for: 1m`, para evitar alertas por parpadeos momentáneos), dispara la alerta hacia Alertmanager, que decide cómo notificar (email, Slack, etc. — configuración que no vamos a completar en este módulo, pero el mecanismo es este).

---

## 7. PRÁCTICA

1. Levantá tu stack de observabilidad existente y confirmá con `docker ps` que Prometheus, Grafana, Loki y Tempo están corriendo.
2. Consultá `/api/v1/targets` de Prometheus y contá cuántos targets están siendo scrapeados, y cuántos con estado `up`.
3. Entrá a Grafana y confirmá qué data sources ya están configuradas.
4. Creá un panel nuevo en un dashboard con la query `up`.
5. Escribí (sin necesariamente aplicar) una regla de alerta como la de la sección 6, adaptada a un servicio de tu stack.

---

## 8. ERROR INTENCIONAL / DIAGNÓSTICO

```bash
docker stop entrevista-prometheus-1
curl localhost:<puerto-grafana>/api/datasources/proxy/1/api/v1/query?query=up
```

**Diagnóstico:** Grafana va a devolver un error de conexión al intentar consultar Prometheus, porque el contenedor está detenido. Esto ilustra un principio real de observabilidad: **el propio sistema de monitoreo puede fallar**, y necesitás poder diagnosticarlo con las mismas herramientas de todo el curso (`docker ps`, `docker logs`) en vez de asumir ciegamente que "si no hay alertas, todo está bien".

```bash
docker start entrevista-prometheus-1
```

---

## Checklist de cierre del módulo

- [ ] Entiendo los 3 pilares de observabilidad y qué herramienta cubre cada uno.
- [ ] Entiendo el modelo pull de Prometheus y por qué "no responder" es información en sí misma.
- [ ] Levanté mi stack existente y confirmé que scrapea targets correctamente.
- [ ] Creé un dashboard con al menos un panel real en Grafana.
- [ ] Entiendo la estructura de una regla de alerta.

---

**Próximo módulo:** 29 — Ciberseguridad defensiva.
