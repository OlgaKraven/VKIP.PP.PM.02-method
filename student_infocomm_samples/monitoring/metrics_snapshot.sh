#!/usr/bin/env bash
# Снимок метрик хоста для отчёта по практике.
# Использование: bash metrics_snapshot.sh [output_dir]
#   output_dir — куда складывать (по умолчанию ./perf_<timestamp>)

set -euo pipefail

OUT="${1:-./perf_$(date +%Y%m%d_%H%M)}"
mkdir -p "$OUT"
cd "$OUT"

echo "[*] Сбор метрик в каталог $(pwd)"

# CPU
top -b -n 5 -d 1 -o %CPU 2>/dev/null | head -50 > cpu_top.txt || true

# RAM
free -h           > ram_free.txt
vmstat 1 5        > vmstat.txt 2>/dev/null || true

# Диск
iostat -x 1 5     > io_stat.txt 2>/dev/null || \
    df -h         > df.txt

# Сеть
ss -s             > net_summary.txt
ss -tnlp          > listen_ports.txt

# Процессы
ps aux --sort=-%cpu | head -10 > top_cpu.txt
ps aux --sort=-%mem | head -10 > top_mem.txt

# Снимок системы
( command -v inxi > /dev/null && inxi -Fxz   > system_info.txt ) || \
( command -v lshw > /dev/null && lshw -short > system_info.txt ) || \
  uname -a                                   > system_info.txt

# Журнал ошибок за 48 ч
journalctl -p err -b --since "48 hours ago" -o short-iso > diag_journal.log 2>/dev/null || true

# Сводка для отчёта
{
  echo "Snapshot: $(date -Iseconds)"
  echo "Host:     $(hostnamectl --static 2>/dev/null || hostname)"
  echo "Uptime:   $(uptime -p 2>/dev/null || uptime)"
  echo
  echo "=== CPU top processes ==="
  head -10 top_cpu.txt
  echo
  echo "=== RAM ==="
  cat ram_free.txt
  echo
  echo "=== Listen ports ==="
  cat listen_ports.txt
} > snapshot_summary.txt

echo "[+] Готово. Каталог: $(pwd)"
ls -la
