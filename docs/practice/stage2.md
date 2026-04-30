# Этап 2. Базовая настройка сети и защита от НСД

## Задание

На данном этапе необходимо:

1. Изучить теорию [«Этап 4. Защита от НСД»](../theory/stage4.md).
2. Настроить сетевую конфигурацию хоста (статический IP, маршрут, DNS).
3. Настроить межсетевой экран (`ufw`/`iptables` или Брандмауэр Windows) — закрыть всё, кроме разрешённых портов.
4. Настроить контроль подключений к СУБД (`pg_hba.conf` / правила `mysql.user`).
5. Настроить парольную политику и базовые ограничения учётных записей.
6. Проверить корректность сетевой настройки и защиты от НСД.
7. Зафиксировать результаты в отчёте.

Этот этап покрывает критерии **ПК 2.1** (сетевое ПО + ПО для защиты от НСД) и **ПК 2.2** (проверка после настройки сетевой инфраструктуры).

---

## Шаг 1. Сетевая конфигурация

### 1.1. Linux (`netplan`)

`/etc/netplan/01-static.yaml`:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.10.42/24]
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses: [192.168.10.1, 1.1.1.1]
```

```bash
sudo netplan apply
ip a show eth0
ip route
ping -c 2 192.168.10.1
ping -c 2 ya.ru
```

### 1.2. Windows (PowerShell)

```powershell
$alias = "Ethernet0"

Remove-NetIPAddress -InterfaceAlias $alias -Confirm:$false
New-NetIPAddress -InterfaceAlias $alias `
                 -IPAddress 192.168.10.42 -PrefixLength 24 `
                 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias $alias `
                           -ServerAddresses ("192.168.10.1","1.1.1.1")

Get-NetIPConfiguration -InterfaceAlias $alias
Test-NetConnection 192.168.10.1
```

> 📌 Конкретные IP/маски нужно выдержать соответствующими стенду варианта; в учебной папке `student_infocomm_samples/network_config/` — два готовых примера для Linux и Windows.

---

## Шаг 2. Межсетевой экран (хостовый МЭ)

### 2.1. Linux + `ufw`

```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp                                         # SSH
sudo ufw allow from 192.168.10.0/24 to any port 5432 proto tcp # PostgreSQL только из LAN
sudo ufw allow from 192.168.10.0/24 to any port 3306 proto tcp # MySQL только из LAN

sudo ufw enable
sudo ufw status verbose
```

### 2.2. Linux + `iptables`

```bash
sudo iptables -F
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -s 192.168.10.0/24 -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
sudo iptables -P INPUT DROP
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### 2.3. Windows

```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private `
                       -Enabled True `
                       -DefaultInboundAction Block `
                       -DefaultOutboundAction Allow

New-NetFirewallRule -DisplayName "RDP from LAN" -Direction Inbound `
                    -Protocol TCP -LocalPort 3389 `
                    -RemoteAddress 192.168.10.0/24 -Action Allow

New-NetFirewallRule -DisplayName "MSSQL from LAN" -Direction Inbound `
                    -Protocol TCP -LocalPort 1433 `
                    -RemoteAddress 192.168.10.0/24 -Action Allow

Get-NetFirewallRule | Where-Object Enabled -eq True |
    Select DisplayName, Direction, Action
```

---

## Шаг 3. Контроль подключений к СУБД

### 3.1. PostgreSQL — `pg_hba.conf`

`/etc/postgresql/16/main/pg_hba.conf`:

```
# TYPE  DATABASE     USER       ADDRESS            METHOD
local   all          postgres                       peer
local   all          all                            scram-sha-256
host    corpdata_42  client01,client02   192.168.10.0/24    scram-sha-256
host    corpdata_42  client03            192.168.10.50/32   scram-sha-256
host    all          all                 0.0.0.0/0          reject
```

В `/etc/postgresql/16/main/postgresql.conf`:

```
listen_addresses = '127.0.0.1, 192.168.10.42'
password_encryption = scram-sha-256
```

```bash
sudo systemctl reload postgresql
```

### 3.2. MySQL

```sql
RENAME USER 'client01'@'%' TO 'client01'@'192.168.10.%';
RENAME USER 'client02'@'%' TO 'client02'@'192.168.10.%';
FLUSH PRIVILEGES;

SELECT user, host FROM mysql.user;
```

### 3.3. Проверка после правок

```bash
psql -h 192.168.10.42 -U client01 -d corpdata_42         # из LAN — должно сработать
psql -h 192.168.10.42 -U client01 -d corpdata_42         # с публичного IP — отказ
```

---

## Шаг 4. Парольная политика и ограничения учётных записей

### 4.1. Linux

```bash
# Сложность пароля (cracklib)
sudo apt install -y libpam-cracklib

# Длина и срок действия для существующих пользователей
for u in dbadmin_42 client01 client02 client03 client04 client05; do
    sudo chage -M 90 -m 7 -W 14 "$u" 2>/dev/null
done

# Запретить пустые пароли в SSH
sudo sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### 4.2. Windows

```powershell
net accounts /minpwlen:8 /maxpwage:90 /minpwage:1 /uniquepw:5

# отключить «гостя» и неиспользуемые учётки
Disable-LocalUser -Name "Guest"

# заблокировать после 5 неудачных попыток
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15
```

---

## Шаг 5. Проверка работоспособности и защиты

### 5.1. Сеть

```bash
ip a | grep -A2 eth0
ip route
ping -c 2 192.168.10.1
nslookup ya.ru
```

### 5.2. Открытые порты с самого хоста

```bash
ss -tnlp
sudo ss -tnlp | grep -E '22|5432|3306|3389'
```

### 5.3. Открытые порты снаружи

С другого ПК / телефона / ВМ в той же сети:

```bash
nmap -p 22,80,443,3306,5432,3389 192.168.10.42
```

В отчёт — таблица:

| Порт | Назначение | Должен быть открыт? | Факт | Соответствует? |
|:---:|------------|:------------------:|:----:|:--------------:|
| 22  | SSH | да (LAN) | открыт | да |
| 80  | HTTP | нет | закрыт | да |
| 443 | HTTPS | нет | закрыт | да |
| 5432 | PostgreSQL | да (LAN) | открыт | да |
| 3306 | MySQL | да (LAN) | открыт | да |
| 3389 | RDP | да (LAN, Windows) | открыт | да |

### 5.4. Пробы прав

| Сценарий | Ожидание |
|----------|----------|
| Подключение `client03` и попытка `INSERT` | отказ |
| Подключение `client01` с публичного IP | отказ |
| Вход по SSH под `root` | отказ |
| Пустой пароль | отказ |

### 5.5. Журналы

```bash
sudo tail -50 /var/log/auth.log
sudo journalctl -u ssh -e
sudo lastb | head             # неудачные попытки входа
```

---

## Чек-лист этапа 2

| Вопрос | ПК | Да/нет | Комментарий |
|--------|:--:|:------:|-------------|
| Хост получил статический IP/маршрут/DNS? | 2.1, 2.2 |  |  |
| МЭ хоста включён, по умолчанию `deny`? | 2.1 |  |  |
| Открыты только нужные порты, ограничены по сети? | 2.1, 2.3 |  |  |
| СУБД слушает только нужные адреса? | 2.1 |  |  |
| `pg_hba.conf` ограничивает по `DATABASE/USER/ADDR`? | 2.3 |  |  |
| Парольная политика задана (длина, срок, лок-аут)? | 2.3 |  |  |
| `root`/`Administrator` не пускается по SSH/RDP напрямую? | 2.3 |  |  |
| Внешний `nmap` подтверждает: лишние порты закрыты? | 2.2 |  |  |
| Запрещённая операция в БД даёт отказ? | 2.2 |  |  |
| Журналы входа сохранены / просмотрены? | 2.4 |  |  |

---

## Что приложить к отчёту по этапу 2

1. Файл `01-static.yaml` (Linux) или экспорт `Get-NetIPConfiguration` (Windows).
2. Текущие правила МЭ: `sudo ufw status verbose` / `Get-NetFirewallRule -Enabled True`.
3. Фрагменты `pg_hba.conf` и `postgresql.conf` (правки).
4. Результат `nmap` снаружи.
5. Скриншоты неудачных попыток подключения (по сети, по правам, по логину/паролю).
6. Выводы по этапу: что закрыто, какие риски остались.
