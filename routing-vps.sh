#!/bin/bash

# ===============================
# 🚀 Fully Optimized Forwarding VPS Script
# ===============================

# Prompt for the Main VPS IP
read -p "Enter the Main VPS IP: " MAIN_VPS_IP

# -------------------------------
# 1️⃣ Enable IP forwarding
# -------------------------------
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# -------------------------------
# 2️⃣ MASQUERADE / NAT setup
# -------------------------------
echo "Setting up NAT..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A PREROUTING -j DNAT --to-destination $MAIN_VPS_IP
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -d $MAIN_VPS_IP -j ACCEPT
iptables -A FORWARD -s $MAIN_VPS_IP -j ACCEPT

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# -------------------------------
# 3️⃣ Adaptive throughput optimization
# -------------------------------
echo "Applying throughput optimization..."
TOTAL_RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}')
CPU_CORES=$(nproc)

RMEM_MAX=16777216
WMEM_MAX=16777216
RMEM_DEFAULT=262144
WMEM_DEFAULT=262144
TCP_RMEM_MIN=4096
TCP_RMEM_DEFAULT=87380
TCP_RMEM_MAX=16777216
TCP_WMEM_MIN=4096
TCP_WMEM_DEFAULT=65536
TCP_WMEM_MAX=16777216
NETDEV_MAX_BACKLOG=2500

if (( $(echo "$TOTAL_RAM_MB < 1500" | bc -l) )); then
    RMEM_MAX=8388608
    WMEM_MAX=8388608
    TCP_RMEM_MAX=8388608
    TCP_WMEM_MAX=8388608
    NETDEV_MAX_BACKLOG=1000
fi

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

# -------------------------------
# 4️⃣ Latency / NAT / TTL optimizations
# -------------------------------
echo "Applying TTL / MSS / RPF / Keepalive..."
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu --tcp-option 2
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.tcp_keepalive_time=30
sysctl -w net.ipv4.icmp_echo_ignore_all=0
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0

# -------------------------------
# 5️⃣ Optional ECMP / Multi-path (if multiple gateways exist)
# -------------------------------
# Example:
# ip route add default nexthop via <GW1> dev eth0 weight 1 nexthop via <GW2> dev eth0 weight 1
# Uncomment and set GW1 / GW2 if Forwarding VPS has multiple uplinks

# -------------------------------
# 6️⃣ Save sysctl persistently
# -------------------------------
cat <<EOF >/etc/sysctl.d/99-forwarding-vps.conf
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
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.tcp_keepalive_time=30
net.ipv4.icmp_echo_ignore_all=0
net.ipv4.icmp_echo_ignore_broadcasts=0
EOF

sysctl --system >/dev/null 2>&1

echo "✅ Forwarding VPS fully optimized (friend’s VPS level)!"
