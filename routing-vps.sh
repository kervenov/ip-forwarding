#!/bin/bash

read -p "Enter the Main VPS IP: " MAIN_VPS_IP

echo "▶ Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

echo "▶ Tuning conntrack for high traffic..."

# Apply at runtime
sysctl -w net.netfilter.nf_conntrack_max=262144
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=7200

# Persist settings
grep -q "^net.netfilter.nf_conntrack_max" /etc/sysctl.conf || \
echo "net.netfilter.nf_conntrack_max=262144" >> /etc/sysctl.conf

grep -q "^net.netfilter.nf_conntrack_tcp_timeout_established" /etc/sysctl.conf || \
echo "net.netfilter.nf_conntrack_tcp_timeout_established=7200" >> /etc/sysctl.conf

echo "▶ Detecting main network interface..."
NET_IFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
echo "Detected interface: $NET_IFACE"

echo "▶ Flushing previous iptables rules..."
iptables -t nat -F
iptables -F FORWARD

echo "▶ Setting DNAT (NEW connections only)..."
iptables -t nat -A PREROUTING -m conntrack --ctstate NEW -j DNAT --to-destination "$MAIN_VPS_IP"

echo "▶ Setting SNAT / MASQUERADE..."
iptables -t nat -A POSTROUTING -o "$NET_IFACE" -j MASQUERADE

echo "▶ Allowing established connections (fast path)..."
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "▶ Allowing forwarding to/from main VPS..."
iptables -A FORWARD -d "$MAIN_VPS_IP" -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -s "$MAIN_VPS_IP" -j ACCEPT

echo "▶ Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "✅ Forwarding VPS fully optimized & rotation-ready!"
