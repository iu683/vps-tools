#!/bin/bash

# 颜色定义
white="\033[37m"
purple="\033[35m"
re="\033[0m"

# ASCII VPS Logo
printf "${purple}"
printf " _    __ ____   _____ \n"
printf "| |  / // __ \\ / ___/ \n"
printf "| | / // /_/ / \\__ \\  \n"
printf "| |/ // ____/ ___/ /  \n"
printf "|___//_/     /____/   \n"
printf "${re}"

# 安装依赖函数，兼容更多发行版
install_dependencies() {
  if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y curl vnstat lsb-release || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl vnstat redhat-lsb-core || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl vnstat redhat-lsb-core || true
  elif command -v zypper >/dev/null 2>&1; then
    zypper install -y curl vnstat lsb-release || true
  else
    printf "%b未识别包管理器，跳过依赖安装%b\n" "$white" "$re"
  fi
}

install_dependencies

# 获取 IP 地址（带失败判断）
ipv4_address=$(curl -s --max-time 5 ipv4.icanhazip.com)
[ -z "$ipv4_address" ] && ipv4_address="无法获取"
ipv6_address=$(curl -s --max-time 5 ipv6.icanhazip.com)
[ -z "$ipv6_address" ] && ipv6_address="无法获取"

clear

# CPU 信息获取，兼容多环境
get_cpu_info() {
  if grep -q 'model name' /proc/cpuinfo 2>/dev/null; then
    grep 'model name' /proc/cpuinfo | head -1 | sed -r 's/model name\s*:\s*//'
  elif command -v lscpu >/dev/null 2>&1; then
    lscpu | grep 'Model name' | head -1 | sed -r 's/Model name:\s*//'
  else
    echo "未知 CPU"
  fi
}

cpu_info=$(get_cpu_info)

# CPU 使用率计算，适配更多版本
get_cpu_usage() {
  cpu_line1=($(head -n1 /proc/stat))
  idle1=${cpu_line1[4]}
  total1=0
  for val in "${cpu_line1[@]:1}"; do
    total1=$((total1 + val))
  done
  sleep 1
  cpu_line2=($(head -n1 /proc/stat))
  idle2=${cpu_line2[4]}
  total2=0
  for val in "${cpu_line2[@]:1}"; do
    total2=$((total2 + val))
  done

  idle_diff=$((idle2 - idle1))
  total_diff=$((total2 - total1))
  usage=$(( (1000 * (total_diff - idle_diff) / total_diff + 5) / 10 ))
  echo "${usage}.00%"
}

cpu_usage_percent=$(get_cpu_usage)

cpu_cores=$(nproc)

# 内存 & 硬盘信息
mem_info=$(free -m | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
disk_info=$(df -h / | awk 'NR==2{printf "%d/%dGB (%s)", $3,$2,$5}')

# 地理 & ISP
country=$(curl -s --max-time 3 ipinfo.io/country)
[ -z "$country" ] && country="未知"
city=$(curl -s --max-time 3 ipinfo.io/city)
[ -z "$city" ] && city="未知"
isp_info=$(curl -s --max-time 3 ipinfo.io/org)
[ -z "$isp_info" ] && isp_info="未知"

# 系统信息
cpu_arch=$(uname -m)
hostname=$(hostname)
kernel_version=$(uname -r)
congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "未知")
queue_algorithm=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "未知")

# OS 信息
get_os_info() {
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -ds
  elif [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "$PRETTY_NAME"
  elif [ -f /etc/debian_version ]; then
    echo "Debian $(cat /etc/debian_version)"
  elif [ -f /etc/redhat-release ]; then
    cat /etc/redhat-release
  else
    echo "未知操作系统"
  fi
}
os_info=$(get_os_info)

# 流量单位转换函数
format_bytes() {
  local bytes=$1
  local units=("Bytes" "KB" "MB" "GB" "TB")
  local i=0
  while (( $(echo "$bytes > 1024" | bc -l) )) && (( i < ${#units[@]} - 1 )); do
    bytes=$(echo "scale=2; $bytes/1024" | bc)
    ((i++))
  done
  echo "$bytes ${units[i]}"
}

# 网络流量统计，排除lo接口
get_net_traffic() {
  local rx_total=0
  local tx_total=0
  while read -r line; do
    iface=$(echo $line | awk -F: '{print $1}' | tr -d ' ')
    if [[ "$iface" == "lo" || "$iface" =~ ^docker || "$iface" =~ ^veth ]]; then
      continue
    fi
    rx=$(echo $line | awk '{print $2}')
    tx=$(echo $line | awk '{print $10}')
    rx_total=$((rx_total + rx))
    tx_total=$((tx_total + tx))
  done < <(tail -n +3 /proc/net/dev)

  rx_formatted=$(format_bytes $rx_total)
  tx_formatted=$(format_bytes $tx_total)
  printf "总接收: %s\n总发送: %s\n" "$rx_formatted" "$tx_formatted"
}

output=$(get_net_traffic)

# 时间 & 运行时长
current_time=$(date "+%Y-%m-%d %I:%M %p")

swap_used=$(free -m | awk 'NR==3{print $3}')
swap_total=$(free -m | awk 'NR==3{print $2}')
if [ -z "$swap_total" ] || [ "$swap_total" -eq 0 ]; then
  swap_info="未启用"
else
  swap_percentage=$((swap_used * 100 / swap_total))
  swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"
fi

runtime=$(awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}' /proc/uptime)

# 输出部分，安全使用printf避免错误
printf "%b系统信息详情%b\n" "$white" "$re"
printf "------------------------\n"
printf "%b主机名: %b%s%b\n" "$white" "$purple" "$hostname" "$re"
printf "%b运营商: %b%s%b\n" "$white" "$purple" "$isp_info" "$re"
printf "------------------------\n"
printf "%b系统版本: %b%s%b\n" "$white" "$purple" "$os_info" "$re"
printf "%bLinux版本: %b%s%b\n" "$white" "$purple" "$kernel_version" "$re"
printf "------------------------\n"
printf "%bCPU架构: %b%s%b\n" "$white" "$purple" "$cpu_arch" "$re"
printf "%bCPU型号: %b%s%b\n" "$white" "$purple" "$cpu_info" "$re"
printf "%bCPU核心数: %b%s%b\n" "$white" "$purple" "$cpu_cores" "$re"
printf "------------------------\n"
printf "%bCPU占用: %b%s%b\n" "$white" "$purple" "$cpu_usage_percent" "$re"
printf "%b物理内存: %b%s%b\n" "$white" "$purple" "$mem_info" "$re"
printf "%b虚拟内存: %b%s%b\n" "$white" "$purple" "$swap_info" "$re"
printf "%b硬盘占用: %b%s%b\n" "$white" "$purple" "$disk_info" "$re"
printf "------------------------\n"
printf "%b%s%b\n" "$purple" "$output" "$re"
printf "------------------------\n"
printf "%b网络拥堵算法: %b%s %s%b\n" "$white" "$purple" "$congestion_algorithm" "$queue_algorithm" "$re"
printf "------------------------\n"
printf "%b公网IPv4地址: %b%s%b\n" "$white" "$purple" "$ipv4_address" "$re"
printf "%b公网IPv6地址: %b%s%b\n" "$white" "$purple" "$ipv6_address" "$re"
printf "------------------------\n"
printf "%b地理位置: %b%s %s%b\n" "$white" "$purple" "$country" "$city" "$re"
printf "%b系统时间: %b%s%b\n" "$white" "$purple" "$current_time" "$re"
printf "------------------------\n"
printf "%b系统运行时长: %b%s%b\n" "$white" "$purple" "$runtime" "$re"
printf "\n"
