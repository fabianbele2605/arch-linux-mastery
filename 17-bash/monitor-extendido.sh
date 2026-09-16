#!/usr/bin/env bash
set -euo pipefail

trap 'echo; echo "Monitor finalizado"' EXIT

chequear_espacio() {
    local ruta="$1"
    local uso
    uso=$(df --output=pcent "$ruta" | tail -n1 | tr -dc '0-9')
    if (( uso >= 90 )); then
        echo "⚠️  ALERTA: $ruta está al ${uso}% de uso" >&2
        return 1
    fi
    return 0
}

modo_breve="${1:-}"

echo "=== Monitor del sistema — $(date) ==="
echo

echo "--- CPU y carga ---"
uptime

echo
echo "--- Memoria ---"
free -h

if [[ "$modo_breve" == "--breve" ]]; then
    exit 0
fi

echo
echo "--- Disco ---"
df -h / /boot

echo
echo "--- Verificación de espacio (umbral 90%) ---"
chequear_espacio "/" || echo "(revisar la partición raíz)"
chequear_espacio "/boot" || echo "(revisar /boot)"

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
