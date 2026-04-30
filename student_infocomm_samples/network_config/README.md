# Сетевые конфиги — учебные шаблоны

Содержимое:

- `01-static.yaml` — статическая IP-конфигурация для `netplan` (Ubuntu/Astra Server).
- `ufw.rules` — список правил `ufw` для базовой защиты хоста.
- `iptables.sh` — bash-скрипт, разворачивающий минимальный набор правил `iptables`.
- `sysctl.conf` — параметры ядра для базовой защиты сетевого стека.

## Применение

```bash
# Адрес и шлюз
sudo cp 01-static.yaml /etc/netplan/01-static.yaml
sudo netplan apply

# Брандмауэр (ufw)
sudo apt install -y ufw
while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    sudo ufw $line
done < ufw.rules
sudo ufw enable
sudo ufw status verbose

# Альтернатива — iptables
sudo bash iptables.sh

# Параметры ядра
sudo cp sysctl.conf /etc/sysctl.d/99-stand.conf
sudo sysctl --system
```

> Замените `192.168.10.42`, `192.168.10.0/24`, `192.168.10.1` на адресацию вашего стенда.
