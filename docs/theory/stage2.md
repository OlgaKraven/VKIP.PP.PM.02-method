# Этап 2. Установка и настройка системного и прикладного ПО, СУБД

## 1. Этапы установки ПО

| Шаг | Действие | Результат |
|:---:|----------|-----------|
| 1 | Подбор и проверка совместимости (ОС, разрядность, версия) | подтверждённый дистрибутив |
| 2 | Загрузка с официального источника | проверенная контрольная сумма |
| 3 | Создание сервисной учётной записи и каталогов | владелец и права заданы |
| 4 | Запуск установщика (или `apt install`/`dnf install`) | ПО установлено |
| 5 | Первичная настройка через мастер или конфиг-файл | сервис стартует |
| 6 | Запуск службы и автозапуск | `enabled` + `running` |
| 7 | Проверка — версия, порт, подключение, журнал | сервис обслуживает запросы |
| 8 | Документирование | конфиг сохранён, есть скриншоты |

> **Важно (ПК 2.2).** Без шага 7 «правильно установлено» означает только «установка не завершилась ошибкой». В акте проверки фиксируются конкретные пункты: версия, порт, подключение клиента, отсутствие ошибок в логе.

---

## 2. Установка системного ПО на Linux

### 2.1. Обновление индексов и системы

```bash
sudo apt update
sudo apt -y upgrade
```

### 2.2. Установка типового набора администратора

```bash
sudo apt install -y vim curl wget git net-tools htop tmux ufw
```

### 2.3. Установка СУБД PostgreSQL

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
sudo systemctl status postgresql
ss -tnlp | grep 5432
```

Проверка после установки:

```bash
sudo -u postgres psql -c 'SELECT version();'
```

### 2.4. Установка СУБД MySQL

```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
sudo mysql_secure_installation        # задать пароль root и снять дефолты
mysql --version
```

### 2.5. Управление службами через `systemctl`

| Команда | Назначение |
|---------|------------|
| `systemctl start <unit>`     | запустить службу немедленно |
| `systemctl stop <unit>`      | остановить |
| `systemctl restart <unit>`   | перезапустить (применить новый конфиг) |
| `systemctl reload <unit>`    | перечитать конфиг без остановки |
| `systemctl enable <unit>`    | включить автозапуск |
| `systemctl disable <unit>`   | выключить автозапуск |
| `systemctl status <unit>`    | состояние, последние строки журнала |
| `journalctl -u <unit> -e`    | расширенный журнал службы |

---

## 3. Установка системного ПО на Windows

### 3.1. Менеджеры пакетов

```powershell
winget install --id PostgreSQL.PostgreSQL
winget install --id Microsoft.SQLServer.2022.Express
winget install --id dbeaver.dbeaver
```

### 3.2. Управление службами PowerShell

```powershell
Get-Service postgresql*
Start-Service postgresql-x64-16
Set-Service  postgresql-x64-16 -StartupType Automatic
Stop-Service postgresql-x64-16
```

### 3.3. Учётные записи для служб

- доменная или локальная сервисная учётная запись (NetworkService / Local System / отдельный пользователь);
- запрещён интерактивный вход (`Deny log on locally`);
- пароль не выводится в открытый вид; ротация по политике.

---

## 4. Развёртывание СУБД

### 4.1. PostgreSQL

```bash
sudo -u postgres psql <<'SQL'
CREATE DATABASE corpdata_42;

CREATE USER client01 WITH PASSWORD 'StrongPass#1A';
CREATE USER client02 WITH PASSWORD 'StrongPass#2B';
CREATE USER client03 WITH PASSWORD 'StrongPass#3C';
CREATE USER client04 WITH PASSWORD 'StrongPass#4D';
CREATE USER client05 WITH PASSWORD 'StrongPass#5E';

\c corpdata_42

CREATE TABLE clients (
    id        SERIAL PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE,
    reg_date  DATE NOT NULL DEFAULT CURRENT_DATE
);

GRANT SELECT, INSERT          ON clients TO client01, client02;
GRANT SELECT                  ON clients TO client03;
GRANT SELECT, UPDATE          ON clients TO client04;
GRANT SELECT, DELETE          ON clients TO client05;
SQL
```

### 4.2. MySQL

```sql
CREATE DATABASE corpdata_42 CHARACTER SET utf8mb4;
CREATE USER 'client01'@'%' IDENTIFIED BY 'StrongPass#1A';
GRANT SELECT, INSERT ON corpdata_42.clients TO 'client01'@'%';
FLUSH PRIVILEGES;
```

### 4.3. Дамп БД

```bash
pg_dump -U postgres corpdata_42 > corpdata_42.sql
mysqldump -u root -p corpdata_42 > corpdata_42.sql
```

### 4.4. Проверка работоспособности из стороннего клиента

```bash
psql -h 127.0.0.1 -U client01 -d corpdata_42 -c "INSERT INTO clients(name,email) VALUES ('Anna','a@example.com');"
psql -h 127.0.0.1 -U client03 -d corpdata_42 -c "DELETE FROM clients;"   # должна быть ошибка прав
```

---

## 5. Сетевое ПО

| Сервис | Linux | Windows | Порт |
|--------|-------|---------|:----:|
| DNS | `bind9`, `dnsmasq` | DNS Server (роль) | 53 |
| DHCP | `isc-dhcp-server`, `kea` | DHCP Server (роль) | 67/68 |
| Web | `nginx`, `apache2` | IIS | 80/443 |
| Прокси | `squid` | Forefront TMG / WPS | 3128 |
| OpenVPN/WG | `openvpn`, `wg-quick` | OpenVPN, WireGuard | 1194/51820 |
| SSH/RDP | `openssh-server` | Remote Desktop Services | 22 / 3389 |

### 5.1. SSH (минимальная настройка)

```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### 5.2. nginx как обратный прокси

```nginx
server {
    listen 80;
    server_name app.local;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 6. Прикладное ПО

| Категория | Примеры | Что важно для оператора |
|-----------|---------|--------------------------|
| Офис | Р7-Офис, МойОфис, MS Office | автоматическая активация, шаблоны организации |
| ERP/учёт | 1С: Предприятие, Парус | сервер 1С + MS SQL/PostgreSQL |
| CRM | Битрикс24, AmoCRM | веб-сервер + БД, бэкап, права |
| СЭД | Тезис, Directum | связка с AD/LDAP |
| Антивирус | KасперскийED, Доктор Веб | управляющий сервер, групповые политики |
| Резервное копирование | RuBackup, Veeam, `rsnapshot` | расписание, проверка восстановления |

Установка прикладного ПО оператором обычно сводится к:

1. подготовке (создание ВМ/папки, привилегированной учётной записи, доступа к БД);
2. запуску установщика и заполнению мастера настройки;
3. подключению к СУБД (DSN, строка подключения, пользователь);
4. проверке: вход пользователя, типовая операция, журнал;
5. созданию резервной копии настройки.

---

## 7. Конфигурационные файлы как источник истины

- Хранить **только итоговый рабочий конфиг** — без устаревших секций.
- Все секреты выносить в `.env` или хранилище (Vault, BitWarden); в самом конфиге — переменные.
- Подкаталог `etc/` в проекте практики дублирует структуру `/etc/` — это позволяет сохранять конфиги вместе с отчётом.
- Любая правка конфига сопровождается **перезапуском или reload** соответствующей службы и проверкой по чек-листу из раздела 1.

> 📌 В рамках отчёта нужно приложить конфиги PostgreSQL/MySQL, `nginx.conf`, `sshd_config`, `ufw.rules` (если редактировались) — фрагментами, не как двоичные файлы.

---

## 8. Типичные ошибки на этапе установки

| Симптом | Где смотреть | Что обычно не так |
|---------|--------------|-------------------|
| Служба не стартует | `systemctl status`, `journalctl -u` | права на каталог данных, занятый порт, ошибка конфига |
| Клиент не подключается локально | `ss -tnlp` | служба слушает только `127.0.0.1`, нужно `listen_addresses = '*'` |
| Клиент не подключается с другого ПК | `ufw status`, `iptables -L`, журнал | закрыт порт на МЭ, нет правила `pg_hba.conf` |
| Нет места под БД | `df -h`, `du -sh` | каталог данных на маленьком разделе |
| Запросы тормозят | `top`, `iotop`, журнал СУБД | нет настройки кэшей (`shared_buffers`), мало RAM |
| Не работает после перезагрузки | `systemctl is-enabled` | служба не добавлена в автозапуск |

Эти кейсы будут отрабатываться на практике — этап 1 (СУБД) и этап 3 (мониторинг).
