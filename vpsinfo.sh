#!/bin/bash

# 颜色定义
white="\033[37m"
purple="\033[35m"
re="\033[0m"

# ASCII VPS Logo
echo -e "${purple}"
echo " _    __ ____   _____ "
echo "| |  / // __ \ / ___/ "
echo "| | / // /_/ / \__ \  "
echo "| |/ // ____/ ___/ /  "
echo "|___//_/     /____/   "
echo -e "${re}"

# 自动安装依赖
if [ -f /etc/debian_version ]; then
    apt update -y
    apt install -y curl vnstat lsb-release
elif [ -f /etc/redhat-release ]; then
    yum install -y curl vnstat redhat-lsb-core
fi

# 获取 IP 地址
ipv4_address=$(curl -s ipv4.icanhazip.com)
ipv6_address=$(curl -s ipv6.icanhazip.com)

clear

# CPU 信息
if [ "$(uname -m)" == "x86_64" ]; then
  cpu_info=$(grep 'model name' /proc/cpuinfo | uniq | sed -e 's/model name[[:space:]]*: //')
else
  cpu_info=$(lscpu | grep 'Model name' | sed -e 's/Model name[[:space:]]*: //')
fi
cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')
cpu_usage_percent=$(printf "%.2f" "$cpu_usage")%
cpu_cores=$(nproc)

# 内存 & 硬盘
mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')
disk_info=$(df -h | awk '$NF=="/"{printf "%d/%dGB (%s)", $3,$2,$5}')

# 地理 & ISP
country=$(curl -s ipinfo.io/country)
city=$(curl -s ipinfo.io/city)
isp_info=$(curl -s ipinfo.io/org)

# 系统信息
cpu_arch=$(uname -m)
hostname=$(hostname)
kernel_version=$(uname -r)
congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
queue_algorithm=$(sysctl -n net.core.default_qdisc)

# OS 信息
os_info=$(lsb_release -ds 2>/dev/null)
if [ -z "$os_info" ]; then
  if [ -f "/etc/os-release" ]; then
    os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
  elif [ -f "/etc/debian_version" ]; then
    os_info="Debian $(cat /etc/debian_version)"
  elif [ -f "/etc/redhat-release" ]; then
    os_info=$(cat /etc/redhat-release)
  else
    os_info="Unknown"
  fi
fi

# 网络流量统计
output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
    NR > 2 { rx_total += $2; tx_total += $10 }
    END {
        rx_units = "Bytes";
        tx_units = "Bytes";
        if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
        if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
        if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }
        if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
        if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
        if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }
        printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
    }' /proc/net/dev)

# 时间 & 运行时长
current_time=$(date "+%Y-%m-%d %I:%M %p")
swap_used=$(free -m | awk 'NR==3{print $3}')
swap_total=$(free -m | awk 'NR==3{print $2}')
swap_percentage=$((swap_total==0?0:swap_used * 100 / swap_total))
swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"
runtime=$(awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}' /proc/uptime)

# 输出
echo -e "${white}系统信息详情${re}"
echo "------------------------"
echo -e "${white}主机名: ${purple}${hostname}${re}"
echo -e "${white}运营商: ${purple}${isp_info}${re}"
echo "------------------------"
echo -e "${white}系统版本: ${purple}${os_info}${re}"
echo -e "${white}Linux版本: ${purple}${kernel_version}${re}"
echo "------------------------"
echo -e "${white}CPU架构: ${purple}${cpu_arch}${re}"
echo -e "${white}CPU型号: ${purple}${cpu_info}${re}"
echo -e "${white}CPU核心数: ${purple}${cpu_cores}${re}"
echo "------------------------"
echo -e "${white}CPU占用: ${purple}${cpu_usage_percent}${re}"
echo -e "${white}物理内存: ${purple}${mem_info}${re}"
echo -e "${white}虚拟内存: ${purple}${swap_info}${re}"
echo -e "${white}硬盘占用: ${purple}${disk_info}${re}"
echo "------------------------"
echo -e "${purple}$output${re}"
echo "------------------------"
echo -e "${white}网络拥堵算法: ${purple}${congestion_algorithm} ${queue_algorithm}${re}"
echo "------------------------"
echo -e "${white}公网IPv4地址: ${purple}${ipv4_address}${re}"
echo -e "${white}公网IPv6地址: ${purple}${ipv6_address}${re}"
echo "------------------------"
echo -e "${white}地理位置: ${purple}${country} $city${re}"
echo -e "${white}系统时间: ${purple}${current_time}${re}"
echo "------------------------"
echo -e "${white}系统运行时长: ${purple}${runtime}${re}"
echo
