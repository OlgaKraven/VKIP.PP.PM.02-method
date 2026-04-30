# Мониторинг — учебные конфиги

Содержимое:

- `prometheus.yml` — конфигурация Prometheus, опрашивающего `node_exporter` стенда.
- `node_exporter.service` — `systemd`-юнит для запуска node_exporter.
- `metrics_snapshot.sh` — bash-скрипт быстрого снятия метрик хоста (CPU, RAM, диск, сеть, СУБД).
- `alerts.yml` — пример правил алертинга для Alertmanager.

## Применение

```bash
# 1. node_exporter
sudo useradd -rs /bin/false node_exporter
sudo wget -O /tmp/ne.tgz \
   https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
sudo tar xzf /tmp/ne.tgz -C /tmp/
sudo mv /tmp/node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo cp node_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# 2. Prometheus
sudo apt install -y prometheus
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo cp alerts.yml     /etc/prometheus/alerts.yml
sudo systemctl restart prometheus

# 3. Снятие метрик-снимка
bash metrics_snapshot.sh ./report
```
