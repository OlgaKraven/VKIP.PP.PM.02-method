#!/usr/bin/env bash
# Базовый аудит Linux-хоста.
# Использование: sudo bash audit.sh [output_dir]
# По умолчанию пишет в ./SecurityScan_<timestamp>

set -euo pipefail

OUT="${1:-./SecurityScan_$(date +%Y%m%d_%H%M)}"
mkdir -p "$OUT"
cd "$OUT"

echo "[*] Аудит -> $(pwd)"

# 1. Учётные записи и группы
getent passwd > users.txt
getent group sudo wheel admin 2>/dev/null > sudoers_groups.txt || true
lastlog > lastlog.txt || true

# 2. Парольные политики
grep -E 'PASS_(MAX|MIN)_DAYS|PASS_WARN_AGE' /etc/login.defs > password_policy.txt
grep -hE 'pam_(cracklib|pwquality|tally|faillock)' /etc/pam.d/* 2>/dev/null \
   > pam_settings.txt || true

# 3. Открытые порты
ss -tnlp > listen_ports.txt
ss -unlp > listen_ports_udp.txt

# 4. Активные службы
systemctl list-units --type=service --state=running > running_services.txt

# 5. SUID / SGID
find / -perm /6000 -type f 2>/dev/null > suid_sgid.txt

# 6. Журнал входов
{
  echo "=== last (успешные) ==="
  last -F | head -50
  echo
  echo "=== lastb (неудачные) ==="
  lastb -F 2>/dev/null | head -50 || echo "(требует sudo / нет btmp)"
} > login_history.txt

# 7. Обновления
{
  echo "=== APT pending ==="
  apt list --upgradable 2>/dev/null | tail -n +2
} > pending_updates.txt 2>&1 || true

# 8. SSH
sshd -T 2>/dev/null > sshd_config_effective.txt || \
   cp /etc/ssh/sshd_config sshd_config_effective.txt

# 9. Сводка
{
  echo "Audit: $(date -Iseconds)"
  echo "Host:  $(hostnamectl --static 2>/dev/null || hostname)"
  echo "Kernel: $(uname -r)"
  echo
  echo "=== Listen TCP ports ==="
  awk '{print $4}' listen_ports.txt | sort -u
  echo
  echo "=== Users with shell ==="
  awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1}' users.txt
  echo
  echo "=== Sudoers groups ==="
  cat sudoers_groups.txt 2>/dev/null
  echo
  echo "=== SUID files (count) ==="
  wc -l < suid_sgid.txt
  echo
  echo "=== Pending updates (count) ==="
  grep -c upgradable pending_updates.txt 2>/dev/null || echo 0
} > audit_summary.txt

echo "[+] Готово. См. audit_summary.txt"
ls -la
