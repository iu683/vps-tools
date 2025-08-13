#!/bin/bash

# 颜色定义
white="\033[37m"
purple="\033[35m"
green="\033[32m"
yellow="\033[33m"
red="\033[31m"
re="\033[0m"

# ASCII VPS Logo
printf -- "${purple}"
printf -- " _    __ ____   _____ \n"
printf -- "| |  / // __ \\ / ___/ \n"
printf -- "| | / // /_/ / \\__ \\  \n"
printf -- "| |/ // ____/ ___/ /  \n"
printf -- "|___//_/     /____/   \n"
printf -- "${re}\n"

# 安装依赖函数
install_deps(){
  if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y curl vnstat lsb-release
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl vnstat redhat-lsb-core
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl vnstat redhat-lsb-core
  elif command -v zypper >/dev/null 2>&1; then
    zypper install -y curl vnstat lsb-release
  else
    printf -- "%b未识别的包管理器，跳过依赖安装%b\n" "$white" "$re"
  fi
}
install_deps

# 获取公网IP
ipv4_address=$(curl -s --max-time 5 ipv4.icanhazip.com)
ipv4_address=${ipv4_address:-无法获取}
ipv6_address=$(curl -s --max-time 5 ipv6.icanhazip.com)
ipv6_address=${ipv6_address:-无法获取}

clear

# CPU 信息
get_cpu_info(){
  if grep -q 'model name' /proc/cpuinfo 2>/dev/null; then
    grep 'model name' /proc/cpuinfo | head -1 | sed -r 's/model name\s*:\s*//'
  elif command -v lscpu >/dev/null 2>&1; then
    lscpu | grep 'Model name' | head -1 | sed -r 's/Model name:\s*//'
  else
    echo "未知CPU"
  fi
}
cpu_info=$(get_cpu_info)

get_cpu_usage(){
  local cpu1=($(head -n1 /proc/stat))
  local idle1=${cpu1[4]}
  local total1=0
  for val in "${cpu1[@]:1}"; do total1=$((total1 + val)); done
  sleep 1
  local cpu2=($(head -n1 /proc/stat))
  local idle2=${cpu2[4]}
  local total2=0
  for val in "${cpu2[@]:1}"; do total2=$((total2 + val)); done
  local idle_diff=$((idle2 - idle1))
  local total_diff=$((total2 - total1))
  local usage=0
  if [ $total_diff -ne 0 ]; then
    usage=$((100 * (total_diff - idle_diff) / total_diff))
  fi
  echo "${usage}.00%"
}
cpu_usage_percent=$(get_cpu_usage)
cpu_cores=$(nproc)

# 内存与硬盘
mem_info=$(free -m | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
disk_info=$(df -h / | awk 'NR==2{printf "%d/%dGB (%s)", $3,$2,$5}')

# 地理位置与ISP
country=$(curl -s --max-time 3 ipinfo.io/country)
country=${country:-未知}
city=$(curl -s --max-time 3 ipinfo.io/city)
city=${city:-未知}
isp_info=$(curl -s --max-time 3 ipinfo.io/org)
isp_info=${isp_info:-未知}

# 系统信息
cpu_arch=$(uname -m)
hostname=$(hostname)
kernel_version=$(uname -r)
congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "未知")
queue_algorithm=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "未知")

# OS信息
get_os_info(){
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
    echo "未知系统"
  fi
}
os_info=$(get_os_info)

# 格式化流量
format_bytes(){
  local bytes=$1
  local units=("Bytes" "KB" "MB" "GB" "TB")
  local i=0
  while (( $(echo "$bytes > 1024" | bc -l) )) && (( i < ${#units[@]}-1 )); do
    bytes=$(echo "scale=2; $bytes/1024" | bc)
    ((i++))
  done
  echo "$bytes ${units[i]}"
}

get_net_traffic(){
  local rx_total=0
  local tx_total=0
  while read -r line; do
    iface=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')
    if [[ "$iface" == "lo" ]] || [[ "$iface" == docker* ]] || [[ "$iface" == veth* ]]; then continue; fi
    rx=$(echo "$line" | awk '{print $2}')
    tx=$(echo "$line" | awk '{print $10}')
    rx_total=$((rx_total + rx))
    tx_total=$((tx_total + tx))
  done < <(tail -n +3 /proc/net/dev)
  rx_formatted=$(format_bytes $rx_total)
  tx_formatted=$(format_bytes $tx_total)
  echo "$rx_formatted / $tx_formatted"
}
net_traffic=$(get_net_traffic)

# 时间与运行时长
current_time=$(date "+%Y-%m-%d %I:%M %p")
swap_used=$(free -m | awk 'NR==3{print $3}')
swap_total=$(free -m | awk 'NR==3{print $2}')
if [ -z "$swap_total" ] || [ "$swap_total" -eq 0 ]; then
  swap_info="未启用"
else
  swap_percentage=$((swap_used * 100 / swap_total))
  swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"
fi
runtime=$(awk -F. '{run_days=int($1/86400); run_hours=int(($1%86400)/3600); run_minutes=int(($1%3600)/60); if(run_days>0) printf("%d天 ",run_days); if(run_hours>0) printf("%d时 ",run_hours); printf("%d分\n",run_minutes)}' /proc/uptime)

# 输出双列表格
print_row(){
  local label=$1
  local value=$2
  printf -- "%-20b: %b\n" "$label" "$value"
}

printf -- "%b系统信息详情%b\n" "$white" "$re"
printf -- "----------------------------------------\n"
print_row "主机名" "${purple}$hostname${re}"
print_row "运营商" "${purple}$isp_info${re}"
print_row "系统版本" "${purple}$os_info${re}"
print_row "Linux内核" "${purple}$kernel_version${re}"
print_row "CPU架构" "${purple}$cpu_arch${re}"
print_row "CPU型号" "${purple}$cpu_info${re}"
print_row "CPU核心数" "${purple}$cpu_cores${re}"
print_row "CPU占用" "${green}$cpu_usage_percent${re}"
print_row "物理内存" "${green}$mem_info${re}"
print_row "虚拟内存" "${yellow}$swap_info${re}"
print_row "硬盘占用" "${green}$disk_info${re}"
print_row "网络流量" "${green}$net_traffic${re}"
print_row "TCP拥堵/队列算法" "${purple}$congestion_algorithm / $queue_algorithm${re}"
print_row "公网IPv4" "${purple}$ipv4_address${re}"
print_row "公网IPv6" "${purple}$ipv6_address${re}"
print_row "地理位置" "${purple}$country $city${re}"
print_row "系统时间" "${yellow}$current_time${re}"
print_row "运行时长" "${yellow}$runtime${re}"
printf -- "----------------------------------------\n"
