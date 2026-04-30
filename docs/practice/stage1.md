# Этап 1. Развёртывание стенда и установка СУБД

## Задание

> Соответствует Модулю 2 инвариантной части ДЭ ПУ КОД 09.01.05-1-2026 — «Развёртывание и базовая настройка сервера баз данных, администрирование СУБД и операционной системы».

На данном этапе необходимо:

1. Изучить теоретические материалы [«Этап 1. ИКС, ОС и виртуализация»](../theory/stage1.md) и [«Этап 2. Установка ПО и СУБД»](../theory/stage2.md).
2. Подготовить **изолированную среду**: отдельную виртуальную машину или физический ПК.
3. Развернуть и настроить локальный сервер БД.
4. Создать БД и пользователей с разграничением прав.
5. Проверить работоспособность подключения сторонним клиентом.
6. Выполнить базовое системное администрирование (служебная учётная запись, профиль, точка восстановления).
7. Зафиксировать результаты и подготовить материалы для отчёта.

Все команды выполняются от имени **администратора системы** (через `sudo`/PowerShell от администратора).

В формулах используется **`XY`** — номер вашего рабочего места / варианта (две цифры). Пример: для варианта 4 → `XY = 04`.

---

## ЭТАП 1.1. Развёртывание среды и установка СУБД

### Шаг 1. Подготовка изолированной среды

| Вариант | Что сделать |
|---------|-------------|
| Виртуальная машина | создать новую ВМ с 2 vCPU, 4 ГБ RAM, 30 ГБ диск; ОС — Ubuntu Server 22.04 / Astra Linux SE / Windows Server 2022 |
| Физический ПК | загрузка с LiveUSB либо отдельный пользователь и каталог; подключение к стендовой сети |

Зафиксировать в отчёте:

- гипервизор (Hyper-V / VMware / VirtualBox / KVM) и версия;
- параметры ВМ (vCPU, RAM, диск, сеть);
- ОС: имя, версия, разрядность.

### Шаг 2. Выбор и установка СУБД

Выберите одну из распространённых СУБД и установите её.

#### PostgreSQL (Linux)

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
psql --version
```

Имя сервера задаётся через `cluster_name` в `/etc/postgresql/16/main/postgresql.conf`:

```
cluster_name = 'lab_sql_42'
```

Перезапуск:

```bash
sudo systemctl restart postgresql
sudo -u postgres psql -c "SHOW cluster_name;"
```

#### MySQL (Linux)

```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
sudo mysql_secure_installation
mysql --version
```

#### MS SQL Server Express (Windows)

```powershell
winget install --id Microsoft.SQLServer.2022.Express
winget install --id Microsoft.SQLServerManagementStudio
Get-Service MSSQL$SQLEXPRESS
```

### Шаг 3. Установка визуальной среды администрирования

| СУБД | Клиент |
|------|--------|
| PostgreSQL | **pgAdmin 4** (`sudo apt install pgadmin4-desktop`) или **DBeaver** |
| MySQL | **HeidiSQL**, **DBeaver**, **MySQL Workbench** |
| MS SQL Express | **SSMS** |

### Шаг 4. Зафиксируйте параметры подключения

| Параметр | Пример (PostgreSQL) |
|----------|----------------------|
| Хост | `127.0.0.1` |
| Порт | `5432` |
| Имя сервера / cluster_name | `lab_sql_42` |
| Каталог данных | `/var/lib/postgresql/16/main` |
| Служба ОС | `postgresql.service` |

Команды для проверки:

```bash
sudo -u postgres psql -c "SHOW data_directory;"
sudo -u postgres psql -c "SHOW port;"
ss -tnlp | grep 5432
systemctl status postgresql
```

---

## ЭТАП 1.2. Создание БД и пользователей

> 📌 Замените `XY` на свой номер рабочего места.

### PostgreSQL

```sql
-- 1. Создать БД
CREATE DATABASE corpdata_42;

-- 2. Создать 5 пользователей
CREATE USER client01 WITH PASSWORD 'P@ss-word#1A';
CREATE USER client02 WITH PASSWORD 'P@ss-word#2B';
CREATE USER client03 WITH PASSWORD 'P@ss-word#3C';
CREATE USER client04 WITH PASSWORD 'P@ss-word#4D';
CREATE USER client05 WITH PASSWORD 'P@ss-word#5E';

\c corpdata_42

-- 3. Создать таблицу
CREATE TABLE clients (
    id        SERIAL PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE,
    reg_date  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 4. Назначить права
GRANT SELECT, INSERT  ON clients TO client01, client02;
GRANT SELECT          ON clients TO client03;
GRANT SELECT, UPDATE  ON clients TO client04;
GRANT SELECT, DELETE  ON clients TO client05;

GRANT USAGE, SELECT ON SEQUENCE clients_id_seq TO client01, client02;
```

Генерация надёжных паролей:

```bash
openssl rand -base64 16
pwgen -s 16 5
```

### MySQL

```sql
CREATE DATABASE corpdata_42 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'client01'@'%' IDENTIFIED BY 'P@ss-word#1A';
CREATE USER 'client02'@'%' IDENTIFIED BY 'P@ss-word#2B';
CREATE USER 'client03'@'%' IDENTIFIED BY 'P@ss-word#3C';
CREATE USER 'client04'@'%' IDENTIFIED BY 'P@ss-word#4D';
CREATE USER 'client05'@'%' IDENTIFIED BY 'P@ss-word#5E';

USE corpdata_42;

CREATE TABLE clients (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE,
    reg_date  DATE NOT NULL DEFAULT (CURRENT_DATE)
);

GRANT SELECT, INSERT  ON corpdata_42.clients TO 'client01'@'%', 'client02'@'%';
GRANT SELECT          ON corpdata_42.clients TO 'client03'@'%';
GRANT SELECT, UPDATE  ON corpdata_42.clients TO 'client04'@'%';
GRANT SELECT, DELETE  ON corpdata_42.clients TO 'client05'@'%';
FLUSH PRIVILEGES;
```

> Готовый скрипт лежит в `student_infocomm_samples/postgres_setup/init.sql` и `student_infocomm_samples/mysql_setup/init.sql`.

---

## ЭТАП 1.3. Диагностика и проверка работоспособности

### Шаг 1. Подключение сторонним клиентом

```bash
psql "host=127.0.0.1 user=client01 dbname=corpdata_42" \
     -c "INSERT INTO clients(name,email) VALUES ('Anna','anna@example.com');"

psql "host=127.0.0.1 user=client03 dbname=corpdata_42" \
     -c "DELETE FROM clients;"          # должна быть ошибка прав
```

В DBeaver: создать соединения от каждого пользователя и проверить операции по матрице прав:

| Пользователь | SELECT | INSERT | UPDATE | DELETE |
|--------------|:------:|:------:|:------:|:------:|
| client01 | да | да | нет | нет |
| client02 | да | да | нет | нет |
| client03 | да | нет | нет | нет |
| client04 | да | нет | да | нет |
| client05 | да | нет | нет | да |

### Шаг 2. Дамп БД

```bash
pg_dump -U postgres corpdata_42 > corpdata_42.sql
mysqldump -u root -p corpdata_42 > corpdata_42.sql

head -20 corpdata_42.sql       # первые 10–20 строк — в отчёт
```

### Шаг 3. Скриншоты

Сделать и сохранить скриншоты:

- результат установки СУБД (`psql --version`, окно мастера, версия СУБД);
- создание БД и таблицы;
- список выданных прав;
- успешное подключение клиентом (DBeaver/SSMS);
- попытка нарушить права — отказ.

---

## ЭТАП 1.4. Системное администрирование

### Linux

```bash
# 1. Создать системного пользователя
sudo useradd -m -s /bin/bash dbadmin_42
sudo passwd dbadmin_42

# 2. Профиль: рабочая папка и DB_HOME
sudo -u dbadmin_42 bash -lc 'echo "export DB_HOME=/var/lib/postgresql/16/main" >> ~/.bashrc'

# 3. Каталог отчётов и права
mkdir -p /home/dbadmin_42/sql_reports_42
sudo chown dbadmin_42:dbadmin_42 /home/dbadmin_42/sql_reports_42
sudo chmod 750 /home/dbadmin_42/sql_reports_42
sudo setfacl -m u:client03:r-x /home/dbadmin_42/sql_reports_42
getfacl /home/dbadmin_42/sql_reports_42

# 4. Снимок ВМ или timeshift
sudo apt install -y timeshift
sudo timeshift --create --comments "after-stage1-pm02"
```

### Windows

```powershell
# 1. Создать пользователя
$pwd = Read-Host -AsSecureString
New-LocalUser dbadmin_42 -Password $pwd -FullName "DB Admin 42"
Add-LocalGroupMember -Group "Administrators" -Member dbadmin_42

# 2. Профиль
[Environment]::SetEnvironmentVariable(
    "DB_HOME", "C:\Program Files\PostgreSQL\16", "User"
)

# 3. Каталог и ACL
$dir = "C:\Users\dbadmin_42\Desktop\sql_reports_42"
New-Item -Path $dir -ItemType Directory -Force
icacls $dir /inheritance:r
icacls $dir /grant "Administrators:(OI)(CI)F"
icacls $dir /grant "client03:(OI)(CI)RX"
icacls $dir

# 4. Точка восстановления (Windows 10/11 Pro)
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "after-stage1-pm02" -RestorePointType "MODIFY_SETTINGS"
```

---

## Чек-лист этапа 1

| Вопрос | ПК | Да/нет | Комментарий |
|--------|:--:|:------:|-------------|
| Стенд развёрнут в изолированной среде? | 2.1 |  |  |
| Установлена и работает СУБД? | 2.1 |  |  |
| Имя сервера приведено к виду `lab_sql_XY`? | 2.3 |  |  |
| Зафиксированы порт, каталог данных, имя службы? | 2.3 |  |  |
| Создана БД `corpdata_XY`? | 2.1 |  |  |
| Созданы 5 пользователей с надёжными паролями? | 2.1, 2.3 |  |  |
| Создана таблица `clients` со структурой по ТЗ? | 2.1 |  |  |
| Назначены права по матрице? | 2.3 |  |  |
| Подключение сторонним клиентом успешно? | 2.2 |  |  |
| Запрещённая операция возвращает ошибку прав? | 2.2 |  |  |
| Получен дамп БД? | 2.2 |  |  |
| Создан системный пользователь и его профиль? | 2.3 |  |  |
| Создан каталог отчётов с заданными правами? | 2.3 |  |  |
| Создана точка восстановления / снимок ВМ? | 2.4 |  |  |
| Сделаны скриншоты для отчёта? | — |  |  |

---

## Что приложить к отчёту по этапу 1

1. Имя и версия СУБД, параметры подключения, путь установки.
2. Список созданных пользователей, таблиц и выданных прав (`\du`, `SHOW GRANTS`, или экспорт ACL).
3. Скриншоты:
    - установка СУБД,
    - создание БД и таблиц,
    - права доступа,
    - подключение через клиент (успешное и с отказом).
4. Дамп БД (или его фрагмент — первые 10 строк).
5. Комментарий о настройке ОС: учётная запись, профиль, права на каталог, точка восстановления.
6. Проверка совместимости с инфраструктурой: зависимости, конфликты портов, состояние службы.
7. Проблемы, с которыми столкнулись, и предложения по улучшению.
