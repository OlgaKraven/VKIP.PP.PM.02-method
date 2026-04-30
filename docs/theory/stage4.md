# Этап 4. Защита от несанкционированного доступа и базовое администрирование

## 1. Что такое НСД

**Несанкционированный доступ (НСД)** — получение возможности работать с информацией, ресурсом или сервисом без надлежащих прав. В составе ИКС НСД угрожает:

- АРМ пользователей (вход под чужой учётной записью);
- серверам (получение прав администратора, кражу БД);
- сетевым устройствам (изменение маршрутов, перехват трафика);
- виртуальной инфраструктуре (выход из ВМ, доступ к гипервизору).

Защита от НСД строится по уровням: **физический → сетевой → ОС → приложение → данные**.

---

## 2. Учётные записи и парольные политики

### 2.1. Принципы

- **Принцип наименьших привилегий** — пользователь получает только то, что нужно для работы.
- **Разделение ролей** — администрирование ОС, СУБД и приложения выполняют разные учётные записи.
- **Уникальные пароли** — никаких общих паролей «для всех».
- **Регулярная ротация и контроль** — журнал входа, отключение неиспользуемых учёток.

### 2.2. Linux

```bash
# создать пользователя для администрирования БД
sudo useradd -m -s /bin/bash dbadmin_42
sudo passwd dbadmin_42

# политика паролей через PAM (cracklib)
grep -E 'password.*cracklib' /etc/pam.d/common-password

# срок жизни пароля
sudo chage -M 90 -m 7 -W 14 dbadmin_42
sudo chage -l dbadmin_42

# запрет интерактивного входа служебной учётке
sudo usermod -s /usr/sbin/nologin svc-postgres
```

### 2.3. Windows

```powershell
New-LocalUser -Name dbadmin_42 -Password (Read-Host -AsSecureString) -PasswordNeverExpires:$false
Add-LocalGroupMember -Group "Administrators" -Member dbadmin_42

# политика паролей (локальная)
secedit /export /cfg C:\pol.cfg
# редактируем MinimumPasswordLength, PasswordComplexity = 1
secedit /configure /db secedit.sdb /cfg C:\pol.cfg
```

### 2.4. Требования к паролям (минимум для практики)

- длина — не менее 8 символов;
- буквы разных регистров, цифры, спецсимволы;
- не совпадает с логином и предыдущим паролем;
- генерация: `openssl rand -base64 16`, `pwgen 16 1`, KeePass.

---

## 3. Управление правами доступа

### 3.1. Linux — POSIX-права и ACL

```bash
# базовые
chmod 750 /opt/app
chown -R appuser:appgrp /opt/app

# расширенные (POSIX ACL)
sudo setfacl -m u:client03:r-- /home/dbadmin_42/sql_reports_42
sudo setfacl -m g:audit:r-- /var/log
getfacl /home/dbadmin_42/sql_reports_42
```

### 3.2. Windows — NTFS / `icacls`

```powershell
icacls "C:\DBAdmin_42\sql_reports_42" /inheritance:r
icacls "C:\DBAdmin_42\sql_reports_42" /grant "Administrators:(OI)(CI)F"
icacls "C:\DBAdmin_42\sql_reports_42" /grant "client03:(OI)(CI)RX"
icacls "C:\DBAdmin_42\sql_reports_42"          # проверить итог
```

### 3.3. Права в СУБД

```sql
-- PostgreSQL
GRANT SELECT          ON clients TO client03;
REVOKE INSERT, UPDATE, DELETE ON clients FROM client03;

-- MySQL
GRANT SELECT, INSERT  ON corpdata_42.clients TO 'client01'@'%';
SHOW GRANTS FOR 'client01'@'%';
```

---

## 4. Сетевая защита

### 4.1. МЭ хоста

| Linux (`ufw`) | Windows |
|---------------|---------|
| `sudo ufw default deny incoming` | `Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block` |
| `sudo ufw allow 22/tcp` | `New-NetFirewallRule -DisplayName "RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow` |
| `sudo ufw allow from 192.168.10.0/24 to any port 5432 proto tcp` | `New-NetFirewallRule -DisplayName "PG LAN" -Direction Inbound -Protocol TCP -LocalPort 5432 -RemoteAddress 192.168.10.0/24 -Action Allow` |
| `sudo ufw enable` | `Set-NetFirewallProfile -Enabled True` |
| `sudo ufw status verbose` | `Get-NetFirewallRule | Where-Object Enabled -eq True` |

### 4.2. `iptables` / `nftables`

```bash
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -s 192.168.10.0/24 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### 4.3. Ограничение доступа к СУБД

PostgreSQL `pg_hba.conf`:

```
# TYPE  DATABASE     USER       ADDRESS            METHOD
host    corpdata_42  client01   192.168.10.0/24    scram-sha-256
host    corpdata_42  client03   192.168.10.50/32   scram-sha-256
host    all          all        0.0.0.0/0          reject
```

MySQL — фильтрация на уровне `user@host`:

```sql
CREATE USER 'client01'@'192.168.10.%' IDENTIFIED BY '...';
```

---

## 5. Защита приложений

| Приём | Что даёт |
|-------|----------|
| Не запускать сервис от root/Administrator | при компрометации сервиса не получают полный доступ |
| Хранить секреты в `.env` или Vault | секрет не попадает в репозиторий |
| Включать TLS (HTTPS, `sslmode=require`) | защита от перехвата |
| Включить аутентификацию по ключам (SSH) | пароль не пересылается |
| Подписать сертификаты внутреннего CA | контроль подлинности сервисов |
| Логировать вход и привилегированные действия | расследование инцидентов |

---

## 6. Резервное копирование и точки восстановления

| Объект | Linux | Windows |
|--------|-------|---------|
| ОС | снимок ВМ, `timeshift` | snapshot Hyper-V, точка восстановления (`vssadmin`) |
| Данные | `rsync`, `borgbackup`, `restic` | Robocopy, Veeam |
| СУБД | `pg_dump`, `mysqldump`, `pg_basebackup` | SQL Server Backup, `BACKUP DATABASE ... TO DISK` |
| Конфиги | репозиторий Git, выгрузка `/etc/` | папка с экспортом политик |

Перед серьёзными изменениями (обновление ОС, изменение прав, настройка МЭ) **обязательно создаётся точка восстановления / снимок ВМ**.

---

## 7. Аудит безопасности (минимум для практики)

| Проверка | Linux | Windows |
|----------|-------|---------|
| Просрочка/слабость паролей | `chage -l <user>` | `net accounts` |
| Неактивные учётки | `lastlog` | `Get-LocalUser | Select Name,Enabled,LastLogon` |
| Открытые порты | `ss -tnlp`, `nmap` | `Get-NetTCPConnection -State Listen` |
| SUID/SGID | `find / -perm /6000 -type f 2>/dev/null` | — |
| Активные службы | `systemctl list-units --type=service --state=running` | `Get-Service | Where-Object Status -eq 'Running'` |
| Журнал входа | `journalctl _COMM=sshd`, `last`, `lastb` | события 4624 / 4625 |
| Антивирусные обновления | `freshclam`, отчёт KSC | `Get-MpComputerStatus` |

Результаты собираются в таблицу:

| № | Проверка | Норма | Факт | Отклонение | Рекомендация |
|---|----------|-------|------|------------|--------------|
| 1 | Длина пароля | ≥ 8 | 6 | да | поднять до 12, включить сложность |

---

## 8. Базовое администрирование (по образцу инварианта ДЭ)

В инвариантной части задания (модуль 2 ДЭ ПУ) присутствует пункт **«Системное администрирование»**:

1. создать системного пользователя `dbadmin_XY`;
2. настроить его профиль: рабочая папка `C:\DBAdmin_XY` или `/home/dbadmin_XY`, переменная окружения `DB_HOME`, указывающая на каталог СУБД;
3. создать каталог `sql_reports_XY` и настроить права (Администраторы — полный доступ; `client03` — только просмотр);
4. создать точку восстановления ОС или снимок ВМ.

Реализация на двух платформах:

```bash
# Linux
sudo useradd -m -s /bin/bash dbadmin_42
sudo -u dbadmin_42 mkdir /home/dbadmin_42/sql_reports_42
sudo -u dbadmin_42 bash -lc 'echo export DB_HOME=/var/lib/postgresql/16/main >> ~/.bashrc'
sudo setfacl -m u:client03:r-x /home/dbadmin_42/sql_reports_42
sudo timeshift --create --comments "before-final"
```

```powershell
# Windows
New-LocalUser dbadmin_42 -Password (Read-Host -AsSecureString)
Add-LocalGroupMember -Group "Administrators" -Member dbadmin_42
[Environment]::SetEnvironmentVariable("DB_HOME","C:\Program Files\PostgreSQL\16","User")
New-Item -Path "C:\Users\dbadmin_42\Desktop\sql_reports_42" -ItemType Directory
icacls "C:\Users\dbadmin_42\Desktop\sql_reports_42" /grant "client03:(RX)"
Checkpoint-Computer -Description "before-final" -RestorePointType "MODIFY_SETTINGS"
```

---

## 9. Связь теории с практикой

| Раздел теории | Где применяется |
|---------------|------------------|
| Учётные записи и пароли | этап 1, 2, 4 практики |
| Права POSIX/NTFS | этап 1, 4 практики |
| Права в СУБД | этап 1 практики |
| МЭ и `pg_hba.conf` | этап 2 практики |
| Резервные копии и точки восстановления | этап 1, 4 практики |
| Аудит безопасности | этап 3 практики |
