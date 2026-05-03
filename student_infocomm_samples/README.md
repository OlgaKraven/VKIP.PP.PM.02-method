# Учебные конфиги и скрипты — `student_infocomm_samples`

Готовые шаблоны конфигурации для производственной практики по ПМ.02 «Настройка и обеспечение работоспособности программных и аппаратных средств устройств инфокоммуникационных систем» (профессия 09.01.05 Оператор технической поддержки).

> **Все примеры являются учебными.** Перед использованием на реальном стенде их нужно адаптировать под среду варианта (IP-адресация, имена, пароли). Дефолтные пароли в скриптах — заглушки `P@ss-word#1A` и т.д. Перед запуском замените их на сгенерированные (`openssl rand -base64 16`).

## Состав

| Папка | Содержание |
|-------|------------|
| `postgres_setup/` | `init.sql`, фрагменты `postgresql.conf` и `pg_hba.conf`, `.env.example` |
| `mysql_setup/` | `init.sql`, `my.cnf` (фрагмент), `.env.example` |
| `network_config/` | `01-static.yaml` (netplan), `ufw.rules`, `iptables.sh`, `sysctl.conf` |
| `monitoring/` | `prometheus.yml`, `node_exporter.service`, `metrics_snapshot.sh`, `alerts.yml` |
| `security/` | `password_policy.md`, `audit.sh`, `windows_hardening.md` |

## Быстрый старт

### Linux + PostgreSQL

```bash
sudo apt update && sudo apt install -y postgresql postgresql-contrib ufw
sudo -u postgres psql -f student_infocomm_samples/postgres_setup/init.sql
sudo cp student_infocomm_samples/network_config/01-static.yaml /etc/netplan/
sudo netplan apply
sudo bash student_infocomm_samples/network_config/iptables.sh
```

### Linux + MySQL

```bash
sudo apt update && sudo apt install -y mysql-server ufw
sudo mysql -u root -p < student_infocomm_samples/mysql_setup/init.sql
```

### Мониторинг

```bash
sudo cp student_infocomm_samples/monitoring/node_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now node_exporter
sudo cp student_infocomm_samples/monitoring/prometheus.yml /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
```

## Структура

```
student_infocomm_samples/
├── README.md
├── postgres_setup/
│   ├── README.md
│   ├── init.sql
│   ├── postgresql.conf.fragment
│   ├── pg_hba.conf.example
│   └── .env.example
├── mysql_setup/
│   ├── README.md
│   ├── init.sql
│   ├── my.cnf.fragment
│   └── .env.example
├── network_config/
│   ├── README.md
│   ├── 01-static.yaml
│   ├── ufw.rules
│   ├── iptables.sh
│   └── sysctl.conf
├── monitoring/
│   ├── README.md
│   ├── prometheus.yml
│   ├── node_exporter.service
│   ├── metrics_snapshot.sh
│   └── alerts.yml
└── security/
    ├── README.md
    ├── password_policy.md
    ├── audit.sh
    └── windows_hardening.md
```
