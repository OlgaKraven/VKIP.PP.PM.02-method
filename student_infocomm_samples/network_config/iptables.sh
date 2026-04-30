#!/usr/bin/env bash
# Минимальный набор правил iptables для учебного стенда.
# Запуск: sudo bash iptables.sh
# Сохранение: sudo iptables-save | sudo tee /etc/iptables/rules.v4

set -euo pipefail

LAN="192.168.10.0/24"

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

iptables -A INPUT -p tcp --dport 22                                 -j ACCEPT
iptables -A INPUT -p tcp --dport 5432  -s "${LAN}"                  -j ACCEPT
iptables -A INPUT -p tcp --dport 3306  -s "${LAN}"                  -j ACCEPT
iptables -A INPUT -p tcp --dport 80    -s "${LAN}"                  -j ACCEPT
iptables -A INPUT -p tcp --dport 443   -s "${LAN}"                  -j ACCEPT
iptables -A INPUT -p tcp --dport 9100  -s "${LAN}"                  -j ACCEPT
iptables -A INPUT -p tcp --dport 9090  -s "${LAN}"                  -j ACCEPT

iptables -L -n -v
