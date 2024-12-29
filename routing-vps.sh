#!/bin/bash

# Prompt for the Main VPS IP
read -p "Enter the Main VPS IP: " MAIN_VPS_IP

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Set up NAT for outgoing traffic
echo "Setting up NAT for outgoing traffic..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Forward incoming traffic to the Main VPS (TCP and UDP for OpenVPN)
echo "Forwarding traffic to Main VPS ($MAIN_VPS_IP)..."
iptables -t nat -A PREROUTING -p tcp --dport 1194 -j DNAT --to-destination $MAIN_VPS_IP
iptables -t nat -A PREROUTING -p udp --dport 1194 -j DNAT --to-destination $MAIN_VPS_IP

# Allow forwarding rules
echo "Allowing forwarding rules..."
iptables -A FORWARD -p tcp --dport 1194 -d $MAIN_VPS_IP -j ACCEPT
iptables -A FORWARD -p udp --dport 1194 -d $MAIN_VPS_IP -j ACCEPT

# Ensure the directory exists
echo "Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "Routing VPS setup completed!"
