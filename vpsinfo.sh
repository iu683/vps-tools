#!/bin/bash

# 颜色定义
RED="\033[31m"
PINK="\033[35m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# 获取系统信息
HOSTNAME=$(hostname)
AS_INFO=$(curl -s ipinfo.io/org | sed 's/^[ \t]*//;s/[ \t]*$//')
OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
ARCH=$(uname -m)
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
CPU_CORES=$(nproc)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100-$8"%"}')
MEM_INFO=$(free -m | awk '/Mem/ {printf "%d/%.0f MB (%.2f%%)", $3, $2, $3*100/$2 }')
SWAP_INFO=$(free -m | awk '/Swap/ {printf "%d/%.0f MB (%.2f%%)", $3, $2, ($2==0?0:$3*100/$2) }')
DISK_INFO=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')

# 获取公网 IP 和地理位置
IPV4=$(curl -s ipv4.icanhazip.com)
IPV6=$(curl -s ipv6.icanhazip.com)
CITY=$(curl -s ipinfo.io/city)
COUNTRY=$(curl -s ipinfo.io/country)
DATETIME=$(date +"%Y-%m-%d %I:%M %p")
UPTIME=$(uptime -p | sed 's/up //')

# 网络流量统计（需要 vnstat）
if command -v vnstat &> /dev/null; then
    RX=$(vnstat --oneline | awk -F\; '{print $10}')
    TX=$(vnstat --oneline | awk -F\; '{print $11}')
else
    RX="未知"
    TX="未知"
fi

# BBR 检测
BBR_STATUS=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')

# 输出信息
echo -e "${CYAN}系统信息详情${RESET}"
echo "--------------------------"
echo -e "主机名：${RED}${HOSTNAME}${RESET}"
echo -e "运营商：${RED}${AS_INFO}${RESET}"
echo "--------------------------"
echo -e "系统版本：${RED}${OS_NAME}${RESET}"
echo -e "Linux版本：${RED}${KERNEL}${RESET}"
echo "--------------------------"
echo -e "CPU架构：${RED}${ARCH}${RESET}"
echo -e "CPU型号：${RED}${CPU_MODEL}${RESET}"
echo -e "CPU核心数：${RED}${CPU_CORES}${RESET}"
echo "--------------------------"
echo -e "CPU占用：${RED}${CPU_USAGE}${RESET}"
echo -e "物理内存：${RED}${MEM_INFO}${RESET}"
echo -e "虚拟内存：${RED}${SWAP_INFO}${RESET}"
echo -e "硬盘占用：${RED}${DISK_INFO}${RESET}"
echo "--------------------------"
echo -e "总接收：${RED}${RX}${RESET}"
echo -e "总发送：${RED}${TX}${RESET}"
echo "--------------------------"
echo -e "网络拥堵算法：${YELLOW}${BBR_STATUS}${RESET}"
echo
echo -e "公网 IPv4 地址：${RED}${IPV4}${RESET}"
echo -e "公网 IPv6 地址：${RED}${IPV6}${RESET}"
echo "--------------------------"
echo -e "地理位置：${PINK}${CITY} ${COUNTRY}${RESET}"
echo -e "系统时间：${PINK}${DATETIME}${RESET}"
echo "--------------------------"
echo -e "系统运行时长：${PINK}${UPTIME}${RESET}"
