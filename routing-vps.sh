#!/bin/bash

read -p "Enter the Main VPS IP: " MAIN_VPS_IP

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Detect main interface
NET_IFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

# Flush rules
iptables -t nat -F
iptables -F FORWARD

# DNAT only for NEW incoming connections
iptables -t nat -A PREROUTING -m conntrack --ctstate NEW -j DNAT --to-destination "$MAIN_VPS_IP"

# SNAT / MASQUERADE (ONCE)
iptables -t nat -A POSTROUTING -o "$NET_IFACE" -j MASQUERADE

# Fast path for established connections
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow new connections to main VPS
iptables -A FORWARD -d "$MAIN_VPS_IP" -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -s "$MAIN_VPS_IP" -j ACCEPT

# Save rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "✅ Optimized routing setup completed"
