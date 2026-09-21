# Módulo 27 — DevOps (CI/CD, Ansible, IaC)

**Fase V — Infrastructure & Advanced Systems**

---

## Objetivos del módulo

- Entender qué es CI/CD y por qué automatiza lo que hiciste a mano en módulos anteriores.
- Configurar un pipeline de CI real con GitHub Actions sobre tu propio repositorio.
- Entender Infrastructure as Code (IaC) y automatizar configuración con Ansible.
- Escribir un playbook de Ansible que reproduzca tareas que ya hiciste manualmente en este curso.

---

## 1. CONCEPTO: CI/CD — automatizar lo que ya sabés hacer a mano

**CI (Integración Continua):** cada vez que subís código (`git push`, Módulo 18), un sistema automático lo compila, testea y valida — sin que nadie tenga que acordarse de correr los tests manualmente.

**CD (Entrega/Despliegue Continuo):** si los tests pasan, el sistema automáticamente **despliega** ese código a un servidor real.

**Por qué existe:** ya viviste el problema que esto resuelve, sin nombrarlo — cada vez que corregiste un error a mano y te olvidaste de verificar algo (como el typo de `MODULE_LICENCE` del Módulo 22, o el `VALUE`/`VALUES` del Módulo 26), un pipeline de CI lo habría detectado automáticamente **antes** de que llegara a producción, corriendo las mismas validaciones cada vez, sin cansancio ni distracción humana.

---

## 2. HERRAMIENTA: GitHub Actions sobre tu propio repo

Tu repo `arch-linux-mastery` ya está en GitHub — vamos a agregarle un pipeline de CI real.

```bash
cd ~/Escritorio/Estudios/OS/Arch_linux    # o donde tengas el repo
mkdir -p .github/workflows
nano .github/workflows/check-links.yml
```

```yaml
name: Verificar estructura del curso

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  verificar:
    runs-on: ubuntu-latest
    steps:
      - name: Clonar el repositorio
        uses: actions/checkout@v4

      - name: Contar modulos completados
        run: |
          echo "Modulos con contenido:"
          find . -maxdepth 2 -name "*.md" -not -name "README.md" -not -path "./docs/*" | wc -l

      - name: Verificar que el README existe y no esta vacio
        run: |
          if [ ! -s README.md ]; then
            echo "README.md vacio o inexistente"
            exit 1
          fi
          echo "README.md OK"
```

```bash
git add .github/workflows/check-links.yml
git commit -m "Agregar pipeline de CI con GitHub Actions"
git push
```

Andá a la pestaña **"Actions"** de tu repo en GitHub — vas a ver el workflow ejecutándose automáticamente, cada vez que hagas push. Esto es CI real, corriendo en la infraestructura de GitHub, no en tu VM.

---

## 3. CONCEPTO: Infrastructure as Code (IaC)

Hasta ahora, cada vez que instalaste un paquete, creaste un usuario, o configuraste un servicio, lo hiciste a mano, comando por comando. Si tuvieras que configurar 50 servidores idénticos así, sería inviable y propenso a errores (¿te acordaste de hacer exactamente los mismos pasos, en el mismo orden, en los 50?).

**IaC** significa describir la configuración deseada de un sistema en un archivo declarativo, y dejar que una herramienta se encargue de aplicarla — de forma **idempotente** (correrlo una vez o cien veces produce el mismo resultado final, sin duplicar ni romper nada).

---

## 4. HERRAMIENTA: Ansible

```bash
sudo pacman -S ansible
ansible --version
```

Ansible no necesita agente instalado en las máquinas que gestiona — se conecta por SSH (Módulo 13) y ejecuta comandos remotos. Vamos a usarlo contra tu propia VM (`localhost`), simulando cómo gestionarías servidores reales.

### Inventario

```bash
mkdir -p ~/proyectos/ansible-lab
cd ~/proyectos/ansible-lab
nano inventario.ini
```

```ini
[local]
localhost ansible_connection=local
```

`ansible_connection=local` le dice a Ansible que ejecute directamente en esta máquina (sin SSH), útil para probar sin complicarte con claves.

### Tu primer playbook

```bash
nano playbook.yml
```

```yaml
---
- name: Configurar un servidor basico
  hosts: local
  become: true
  tasks:
    - name: Instalar htop
      pacman:
        name: htop
        state: present

    - name: Asegurar que sshd esta habilitado y corriendo
      systemd:
        name: sshd
        enabled: true
        state: started

    - name: Crear un archivo de marca del playbook
      copy:
        content: "Este servidor fue configurado por Ansible\n"
        dest: /tmp/ansible-marca.txt
```

```bash
ansible-playbook -i inventario.ini playbook.yml
cat /tmp/ansible-marca.txt
```

**Idempotencia en acción:** corré el mismo comando de nuevo:

```bash
ansible-playbook -i inventario.ini playbook.yml
```

Fijate que esta vez Ansible reporta `ok` (sin cambios) en vez de `changed` para las tareas que ya se habían aplicado — no reinstala `htop` de nuevo ni reinicia `sshd` innecesariamente. Esto es exactamente lo que hace a Ansible seguro de correr repetidamente, a diferencia de un script de Bash ingenuo que ejecutaría todo de cero cada vez.

---

## 5. EJEMPLO: comparar con lo que hiciste manualmente

Recordá el Módulo 07 (`sudo pacman -S htop`) y el Módulo 09 (`sudo systemctl enable --now sshd`). El playbook de arriba hizo exactamente eso, pero de forma declarativa: describiste el estado final deseado ("htop instalado", "sshd corriendo"), no la secuencia de comandos para llegar ahí. Esta es la diferencia central entre un script imperativo (Bash, Módulo 17: "hacé esto, después esto") y una herramienta declarativa (Ansible: "quiero que el sistema esté así, resolvé cómo llegar").

---

## 6. PRÁCTICA

1. Agregá el workflow de GitHub Actions al repo, hacé push, y confirmá que corre en la pestaña "Actions".
2. Instalá Ansible y corré el playbook de la sección 4 contra tu propia VM.
3. Corrélo una segunda vez y observá la diferencia entre `changed` y `ok` en la salida.
4. Extendé el playbook agregando una tarea nueva: crear un usuario de sistema con el módulo `user` de Ansible (buscá "ansible user module" en la documentación oficial si hace falta el formato exacto).
5. `ansible-playbook -i inventario.ini playbook.yml --check` — el flag `--check` hace un "dry run" (simula sin aplicar cambios reales). Probalo y compará con una corrida real.

---

## 7. ERROR INTENCIONAL / DIAGNÓSTICO

En `playbook.yml`, cambiá temporalmente `name: htop` por `nam: htop` (typo a propósito) dentro de la tarea de `pacman`, y corré:

```bash
ansible-playbook -i inventario.ini playbook.yml
```

**Diagnóstico:** Ansible va a fallar indicando que `nam` no es un parámetro válido del módulo `pacman` (el correcto es `name`) — un error de validación de esquema, similar a cuando Python te dice que una función no reconoce un argumento. Corregí el typo y volvé a correr.

---

## Checklist de cierre del módulo

- [ ] Entiendo qué resuelve CI/CD frente a validar/desplegar manualmente.
- [ ] Configuré un pipeline real de GitHub Actions sobre mi propio repo.
- [ ] Entiendo Infrastructure as Code y la diferencia entre imperativo (Bash) y declarativo (Ansible).
- [ ] Escribí y corrí un playbook de Ansible, observando la idempotencia en la segunda corrida.
- [ ] Probé el modo `--check` (dry run).

---

**Próximo módulo:** 28 — Observabilidad (Prometheus/Grafana).
