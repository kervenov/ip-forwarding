#!/bin/bash

read -p "Enter the Main VPS IP: " MAIN_VPS_IP

echo "▶ Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null
sysctl -w net.ipv4.ip_forward=1 2>/dev/null

if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

echo "▶ Tuning conntrack for high traffic..."
# Check if nf_conntrack exists before applying
if [ -d /proc/sys/net/netfilter ]; then
    sysctl -w net.netfilter.nf_conntrack_max=262144 2>/dev/null
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=7200 2>/dev/null

    grep -q "^net.netfilter.nf_conntrack_max" /etc/sysctl.conf || \
    echo "net.netfilter.nf_conntrack_max=262144" >> /etc/sysctl.conf

    grep -q "^net.netfilter.nf_conntrack_tcp_timeout_established" /etc/sysctl.conf || \
    echo "net.netfilter.nf_conntrack_tcp_timeout_established=7200" >> /etc/sysctl.conf
else
    echo "⚠ nf_conntrack settings not found, skipping (likely a container)"
fi

echo "▶ Detecting main network interface..."
NET_IFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
echo "Detected interface: $NET_IFACE"

echo "▶ Flushing previous iptables rules..."
iptables -t nat -F 2>/dev/null
iptables -F FORWARD 2>/dev/null

echo "▶ Setting DNAT (NEW connections only)..."
iptables -t nat -A PREROUTING -m conntrack --ctstate NEW -j DNAT --to-destination "$MAIN_VPS_IP" 2>/dev/null

echo "▶ Setting SNAT / MASQUERADE..."
iptables -t nat -A POSTROUTING -o "$NET_IFACE" -j MASQUERADE 2>/dev/null

echo "▶ Allowing established connections (fast path)..."
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null

echo "▶ Allowing forwarding to/from main VPS..."
iptables -A FORWARD -d "$MAIN_VPS_IP" -m conntrack --ctstate NEW -j ACCEPT 2>/dev/null
iptables -A FORWARD -s "$MAIN_VPS_IP" -j ACCEPT 2>/dev/null

echo "▶ Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4 2>/dev/null

echo "✅ Forwarding VPS fully optimized & rotation-ready!"
