#!/bin/bash

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Set up connection tracking for dynamic response routing
echo "Setting up connection tracking for dynamic response routing..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Accept traffic forwarded by any Routing VPS
echo "Allowing traffic from any Routing VPS..."
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp --dport 1194 -j ACCEPT
iptables -A FORWARD -p udp --dport 1194 -j ACCEPT

# Save iptables rules
echo "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

echo "Main VPS setup completed with dynamic routing!"
