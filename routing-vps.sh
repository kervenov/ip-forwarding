#!/bin/bash
set -e

read -p "Main VPS IPv4: " MAIN_VPS

# Detect interface
IFACE=$(ip route get 1 | awk '{print $5; exit}')
SRC_IP=$(ip -4 addr show "$IFACE" | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)

echo "[+] Interface: $IFACE"
echo "[+] Forwarding IP: $SRC_IP"

echo "[+] Enabling IP forwarding"
sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[+] Disabling rp_filter"
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.$IFACE.rp_filter=0 >/dev/null

# Flush old rules
iptables -t nat -F
iptables -F FORWARD

# Default policy
iptables -P FORWARD DROP

# Allow established
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# DNAT (client → main)
iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 80  -j DNAT --to-destination "$MAIN_VPS":80
iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 443 -j DNAT --to-destination "$MAIN_VPS":443

# Allow forward to main
iptables -A FORWARD -d "$MAIN_VPS" -p tcp -m multiport --dports 80,443 -j ACCEPT

# SNAT (EN KRİTİK NOKTA)
iptables -t nat -A POSTROUTING -d "$MAIN_VPS" -p tcp -m multiport --dports 80,443 -j SNAT --to-source "$SRC_IP"

iptables-save > /etc/iptables.rules

echo "✅ Forwarding VPS READY"
