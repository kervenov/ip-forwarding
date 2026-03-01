#!/bin/bash
set -e

echo "[+] Main VPS normal server mode"

# IP forwarding kapalı bile olabilir
sysctl -w net.ipv4.ip_forward=0 >/dev/null

# Firewall varsa sadece 80/443 aç
iptables -F INPUT
iptables -P INPUT DROP

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

iptables-save > /etc/iptables.rules

echo "✅ Main VPS READY"
