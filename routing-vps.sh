#!/bin/bash

# Prompt for the Main VPS IP
read -p "Enter the Main VPS IP: " MAIN_VPS_IP

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Set up NAT for outgoing traffic (MASQUERADE for all traffic)
echo "Setting up NAT for outgoing traffic..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Forward all incoming traffic to the Main VPS (dynamic handling of all ports and protocols)
echo "Forwarding all traffic to Main VPS ($MAIN_VPS_IP)..."
iptables -t nat -A PREROUTING -j DNAT --to-destination $MAIN_VPS_IP

# SNAT to ensure responses go back through Routing VPS
echo "Setting up SNAT to ensure proper routing of responses..."
iptables -t nat -A POSTROUTING -j MASQUERADE

# Allow forwarding rules
echo "Allowing forwarding rules..."
iptables -A FORWARD -d $MAIN_VPS_IP -j ACCEPT
iptables -A FORWARD -s $MAIN_VPS_IP -j ACCEPT

# Save iptables rules
echo "Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "Routing VPS setup completed!"

# ===============================
# 🚀 Dynamic throughput optimization (added)
# ===============================
echo "🚀 Applying throughput optimization for Routing VPS..."

# Detect total RAM in MB and CPU cores
TOTAL_RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}')
CPU_CORES=$(nproc)

# Set buffer sizes based on RAM and cores (adaptive, safe for 1-2 CPU / 1-2GB RAM)
# Minimum values chosen so very small VPS'lerde sorun çıkmasın
RMEM_MAX=16777216      # 16 MB
WMEM_MAX=16777216      # 16 MB
RMEM_DEFAULT=262144    # 256 KB
WMEM_DEFAULT=262144    # 256 KB
TCP_RMEM_MIN=4096
TCP_RMEM_DEFAULT=87380
TCP_RMEM_MAX=16777216
TCP_WMEM_MIN=4096
TCP_WMEM_DEFAULT=65536
TCP_WMEM_MAX=16777216
NETDEV_MAX_BACKLOG=2500

# If VPS is tiny (<1.5GB RAM), scale down slightly
if (( $(echo "$TOTAL_RAM_MB < 1500" | bc -l) )); then
    RMEM_MAX=8388608
    WMEM_MAX=8388608
    TCP_RMEM_MAX=8388608
    TCP_WMEM_MAX=8388608
    NETDEV_MAX_BACKLOG=1000
fi

# Apply the sysctl settings
echo "Setting kernel buffers based on VPS resources..."
sysctl -w net.core.rmem_max=$RMEM_MAX
sysctl -w net.core.wmem_max=$WMEM_MAX
sysctl -w net.core.rmem_default=$RMEM_DEFAULT
sysctl -w net.core.wmem_default=$WMEM_DEFAULT
sysctl -w net.ipv4.tcp_rmem="$TCP_RMEM_MIN $TCP_RMEM_DEFAULT $TCP_RMEM_MAX"
sysctl -w net.ipv4.tcp_wmem="$TCP_WMEM_MIN $TCP_WMEM_DEFAULT $TCP_WMEM_MAX"
sysctl -w net.core.netdev_max_backlog=$NETDEV_MAX_BACKLOG
sysctl -w net.ipv4.tcp_window_scaling=1
sysctl -w net.ipv4.tcp_timestamps=1
sysctl -w net.ipv4.tcp_sack=1
sysctl -w net.ipv4.tcp_no_metrics_save=1

# Save to sysctl.d for persistence
echo "Saving optimization settings to /etc/sysctl.d/99-routing-vps.conf..."
cat <<EOF >/etc/sysctl.d/99-routing-vps.conf
net.core.rmem_max=$RMEM_MAX
net.core.wmem_max=$WMEM_MAX
net.core.rmem_default=$RMEM_DEFAULT
net.core.wmem_default=$WMEM_DEFAULT
net.ipv4.tcp_rmem=$TCP_RMEM_MIN $TCP_RMEM_DEFAULT $TCP_RMEM_MAX
net.ipv4.tcp_wmem=$TCP_WMEM_MIN $TCP_WMEM_DEFAULT $TCP_WMEM_MAX
net.core.netdev_max_backlog=$NETDEV_MAX_BACKLOG
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_no_metrics_save=1
EOF

sysctl --system >/dev/null 2>&1

echo "✅ Throughput optimization applied (dynamic for your VPS resources)."
