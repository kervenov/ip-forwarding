#!/bin/bash

# Prompt for the Main VPS IP
read -p "Enter the Main VPS IP: " MAIN_VPS_IP

# Enable IP forwarding at runtime
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Enable IP forwarding permanently
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Detect main network interface
NET_IFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
echo "Detected network interface: $NET_IFACE"

# Clear previous NAT rules (optional: avoid duplicates)
iptables -t nat -F
iptables -F FORWARD

# Set up full NAT masquerading for outgoing traffic
echo "Setting up NAT for outgoing traffic..."
iptables -t nat -A POSTROUTING -o "$NET_IFACE" -j MASQUERADE

# Forward ALL incoming traffic (all ports & protocols) to Main VPS
echo "Forwarding ALL traffic to Main VPS ($MAIN_VPS_IP)..."
iptables -t nat -A PREROUTING -j DNAT --to-destination "$MAIN_VPS_IP"

# SNAT to ensure responses go back through this VPS
iptables -t nat -A POSTROUTING -j MASQUERADE

# Allow forwarding rules for any protocol to/from Main VPS
echo "Allowing forwarding rules..."
iptables -A FORWARD -d "$MAIN_VPS_IP" -j ACCEPT
iptables -A FORWARD -s "$MAIN_VPS_IP" -j ACCEPT

# Save rules for persistence (requires iptables-persistent)
echo "Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "✅ Routing VPS setup completed!"
