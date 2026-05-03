# Этап 3. Мониторинг производительности и текущий контроль

## Задание

> Этап посвящён комплексной диагностике персонального компьютера, текущему контролю и мониторингу производительности устройств и виртуальных ресурсов.

На данном этапе необходимо:

1. Изучить теорию [«Этап 3. Диагностика, мониторинг и проверка работоспособности»](../theory/stage3.md).
2. Выполнить **анализ журналов и автозагрузки**.
3. Провести **быструю проверку безопасности** (антивирусное сканирование, классификация угроз).
4. Выполнить **мониторинг процессов и загрузки ресурсов**.
5. Настроить **внешний мониторинг** (по выбору варианта — Prometheus/Zabbix/Netdata) для отслеживания виртуальных вычислительных ресурсов.
6. Сформировать таблицу выявленных проблем и рекомендаций.

---

## ЭТАП 3.1. Анализ журналов и автозагрузки

### 3.1.1. Журнал событий

#### Linux

```bash
# критические ошибки за 48 часов
sudo journalctl -p err -b --since "48 hours ago" | head -50

# экспорт в файл для отчёта
sudo journalctl -p err -b --since "48 hours ago" \
     -o short-iso > ~/diag_journal.log
```

#### Windows

```powershell
$evt = Get-WinEvent -FilterHashtable @{
    LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddHours(-48)
}
$evt | Select TimeCreated,LogName,Id,LevelDisplayName,ProviderName,Message |
       Export-Csv -NoTypeInformation -Path .\diag_journal.csv

# экспорт оригинала
wevtutil epl System system_48h.evtx /q:"*[System[(Level=1 or Level=2) and TimeCreated[timediff(@SystemTime) <= 172800000]]]"
```

В отчёт — **3 любые ошибки**: имя события (Event ID), источник (Source), описание, скриншот / экспорт `.evtx` или `.csv`.

### 3.1.2. Автозагрузка

#### Linux

```bash
systemctl list-unit-files --state=enabled --type=service
ls /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/
crontab -l -u root 2>/dev/null
ls -la ~/.config/autostart 2>/dev/null
```

#### Windows

```powershell
Get-CimInstance Win32_StartupCommand | Select Name,Command,Location,User
# или Sysinternals Autoruns
.\Autoruns64.exe -accepteula -nobanner -a * -c | Set-Content autoruns.csv
```

Из элементов автозагрузки выбрать **3 не относящихся к ОС/защитному ПО**, проанализировать необходимость каждого:

| № | Имя | Расположение | Что это | Нужен? | Действие |
|---|-----|--------------|---------|:------:|----------|
| 1 |  |  |  |  |  |
| 2 |  |  |  |  |  |
| 3 |  |  |  |  |  |

---

## ЭТАП 3.2. Быстрая проверка безопасности

### 3.2.1. Антивирусное сканирование

#### Windows

```powershell
mkdir SecurityScan_42
Update-MpSignature
Start-MpScan -ScanType QuickScan
Get-MpThreatDetection | Export-Csv .\SecurityScan_42\threats.csv -NoTypeInformation
Get-MpComputerStatus | Out-File .\SecurityScan_42\status.txt
```

#### Linux

```bash
sudo apt install -y clamav
sudo freshclam
mkdir SecurityScan_42
sudo clamscan -r --infected /home /opt /tmp \
     --log=$PWD/SecurityScan_42/scan.log
```

### 3.2.2. Классификация угроз

| Тип | Что относим |
|-----|-------------|
| Вирус / троян / руткит | подтверждённые антивирусом сигнатуры |
| Потенциально нежелательная программа (ПНП) | майнеры, рекламные браузерные расширения, тулбары |
| Уязвимость конфигурации | пустой пароль, открытый наружу порт, устаревшая версия ПО, выключенное обновление |

В отчёт — таблица:

| № | Объект | Тип | Описание | Действие |
|---|--------|-----|----------|----------|
| 1 |  |  |  |  |

### 3.2.3. Уязвимости конфигурации (минимум)

```bash
# обновления
apt list --upgradable 2>/dev/null | tail -n +2 > pending_updates.txt

# открытые порты (повторно)
sudo ss -tnlp > listen_ports.txt

# SUID-файлы
sudo find / -perm /6000 -type f 2>/dev/null > suid_files.txt
```

```powershell
Get-WindowsUpdate -ErrorAction SilentlyContinue | Out-File pending_updates.txt
Get-NetTCPConnection -State Listen | Out-File listen_ports.txt
```

---

## ЭТАП 3.3. Мониторинг процессов и загрузки ресурсов

### 3.3.1. Снятие текущих метрик (1–2 минуты)

#### Linux

```bash
# CPU/RAM
top -b -n 5 -d 1 -o %CPU | head -50 > cpu_top.txt
free -h                                       > ram_free.txt

# диск
iostat -x 1 5                                 > io_stat.txt

# сеть
ss -s                                         > net_summary.txt
sudo iftop -t -s 30 -P                        > net_iftop.txt 2>&1

# 5 самых тяжёлых процессов
ps aux --sort=-%cpu | head -7                 > top_cpu.txt
ps aux --sort=-%mem | head -7                 > top_mem.txt

# снимок системы
inxi -Fxz                                     > system_info.txt
```

#### Windows

```powershell
$ts = (Get-Date).ToString("yyyyMMdd_HHmm")
mkdir "perf_$ts" | Out-Null

Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 30 |
    Export-Csv "perf_$ts\cpu.csv" -NoTypeInformation
Get-Counter '\Memory\Available MBytes'           -SampleInterval 1 -MaxSamples 30 |
    Export-Csv "perf_$ts\ram.csv" -NoTypeInformation
Get-Process | Sort-Object CPU -Descending | Select -First 10 |
    Export-Csv "perf_$ts\top_proc.csv" -NoTypeInformation

systeminfo            > "perf_$ts\system_info.txt"
dxdiag /t             "$PWD\perf_$ts\dxdiag.txt"
```

### 3.3.2. Что фиксировать

| № | Параметр | Норма | Факт | Отклонение | Комментарий |
|---|----------|------:|-----:|:---------:|-------------|
| 1 | Загрузка CPU средняя | < 60% |  |  |  |
| 2 | Загрузка CPU пиковая | < 90% |  |  |  |
| 3 | Свободно RAM | ≥ 20% |  |  |  |
| 4 | Очередь к диску | < 5 |  |  |  |
| 5 | Топ-1 процесс по CPU |  |  |  |  |
| 6 | Топ-1 процесс по RAM |  |  |  |  |
| 7 | Сетевая активность фоновая |  |  |  |  |

---

## ЭТАП 3.4. Внешний мониторинг (вариативная часть)

> 📌 Если задание варианта требует мониторинга в течение длительного периода — настройте внешний мониторинг. В рамках практики достаточно одной из связок.

### 3.4.1. Prometheus + node_exporter

```bash
# установка node_exporter
sudo useradd -rs /bin/false node_exporter
NEV=1.8.2
wget https://github.com/prometheus/node_exporter/releases/download/v$NEV/node_exporter-$NEV.linux-amd64.tar.gz
tar xzf node_exporter-$NEV.linux-amd64.tar.gz
sudo mv node_exporter-$NEV.linux-amd64/node_exporter /usr/local/bin/

sudo cp student_infocomm_samples/monitoring/node_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo ufw allow from 192.168.10.0/24 to any port 9100 proto tcp

curl -s http://127.0.0.1:9100/metrics | head -20
```

Установка Prometheus:

```bash
sudo apt install -y prometheus
sudo cp student_infocomm_samples/monitoring/prometheus.yml /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
```

Открыть `http://<host>:9090/targets` — состояние таргетов; в раздел `Graph` — построить запросы:

```promql
node_cpu_seconds_total{mode="idle"}
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
rate(node_network_receive_bytes_total[1m])
```

### 3.4.2. Альтернативы

| Инструмент | Установка |
|------------|-----------|
| Netdata | `bash <(curl -SsL https://my-netdata.io/kickstart.sh)` |
| Zabbix-агент 6.x | `apt install zabbix-agent2`; сервер указывает в `/etc/zabbix/zabbix_agent2.conf` |
| Cacti / Munin | реже, но допустимы |

В отчёт — скриншоты дашборда / графиков и краткое описание собранных метрик.

---

## ЭТАП 3.5. Формирование сводной таблицы

| Компонент | Проблема / ошибка | Причина | Рекомендация | Риск для пользователя |
|-----------|-------------------|---------|--------------|------------------------|
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

Также включить в отчёт **общие сведения о системе** (`systeminfo` / `dxdiag` / `lshw -short` / `inxi -F`) и **итоговые рекомендации** по:

- повышению стабильности ОС;
- улучшению производительности;
- базовому обеспечению безопасности.

---

## Чек-лист этапа 3

| Вопрос | ПК | Да/нет | Комментарий |
|--------|:--:|:------:|-------------|
| Просмотрены ошибки журнала за 48 ч (≥ 3 шт.)? | 2.4 |  |  |
| Проанализированы 3 элемента автозагрузки? | 2.4 |  |  |
| Выполнено антивирусное сканирование? | 2.4 |  |  |
| Угрозы классифицированы? | 2.4 |  |  |
| Снят снимок процессов и нагрузки? | 2.4 |  |  |
| Выявлены 2–3 «тяжёлых» процесса? | 2.4 |  |  |
| Включён внешний мониторинг? | 2.4 |  |  |
| Сформирована таблица проблем и рекомендаций? | 2.4 |  |  |

---

## Что приложить к отчёту по этапу 3

1. Экспорт журналов событий (`.csv` / `.evtx` / текст).
2. Список автозагрузки и комментарий по 3 элементам.
3. Папка `SecurityScan_XX/` с отчётом антивируса и `status.txt`.
4. Файлы метрик (`cpu_*.txt`, `ram_*.txt`, `top_*.csv`).
5. Скриншоты Prometheus/Zabbix/Netdata (если использовались).
6. Сводная таблица проблем, рисков и рекомендаций.
