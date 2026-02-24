#!/bin/bash
set -e

read -p "Main VPS IPv4: " MAIN_VPS

echo "[+] Switching to iptables-legacy (Ubuntu safe)"
update-alternatives --set iptables /usr/sbin/iptables-legacy >/dev/null 2>&1 || true
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy >/dev/null 2>&1 || true

# Disable ufw if running
if systemctl is-active --quiet ufw; then
  echo "[+] Disabling UFW"
  ufw disable
fi

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1 >/dev/null
grep -q net.ipv4.ip_forward /etc/sysctl.conf || \
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Detect interface
IFACE=$(ip -4 route show default | awk '{print $5}' | head -n1)
[ -z "$IFACE" ] && IFACE=$(ls /sys/class/net | grep -v lo | head -n1)

echo "[+] Interface: $IFACE"

# Flush rules
iptables -t nat -F
iptables -F FORWARD

# Policies
iptables -P FORWARD ACCEPT

# NAT rules
iptables -t nat -A PREROUTING -j DNAT --to-destination "$MAIN_VPS"
iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

# Forward allow
iptables -A FORWARD -d "$MAIN_VPS" -j ACCEPT
iptables -A FORWARD -s "$MAIN_VPS" -j ACCEPT

# Persist
iptables-save > /etc/iptables.rules 2>/dev/null || true

echo "✅ Ubuntu 20+ forwarding ACTIVE"
