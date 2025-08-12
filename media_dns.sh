#!/bin/bash
# 流媒体解锁 DNS 快捷切换脚本（无检测）

# DNS 列表
declare -A dns_list=(
  ["Def"]="154.83.83.83"
  ["HK"]="154.83.83.84"
  ["JP"]="154.83.83.85"
  ["TW"]="154.83.83.86"
  ["SG"]="154.83.83.87"
  ["US"]="154.83.83.88"
  ["UK"]="154.83.83.89"
  ["DE"]="154.83.83.90"
  ["RFC"]="22.22.22.22"
  ["Cus"]="custom"
)

# 绿色
green="\033[32m"
reset="\033[0m"

# 显示菜单（双列）
echo -e "${green}请选择要使用的 DNS 区域：${reset}"
count=0
for region in "${!dns_list[@]}"; do
    printf "${green}%-10s${reset}" "[$((++count))] $region"
    if (( count % 2 == 0 )); then
        echo ""
    fi
done
echo ""

# 选择输入
read -p "$(echo -e ${green}请输入编号:${reset}) " choice

# 获取对应选项
regions=("${!dns_list[@]}")
if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#regions[@]} )); then
    region="${regions[$((choice-1))]}"
    if [[ "$region" == "Cus" ]]; then
        read -p "$(echo -e ${green}请输入自定义 DNS IP 地址:${reset}) " custom_dns
        dns_to_set="$custom_dns"
    else
        dns_to_set="${dns_list[$region]}"
    fi
else
    echo -e "${green}无效选择，退出。${reset}"
    exit 1
fi

# 应用 DNS
if [[ -n "$dns_to_set" ]]; then
    echo -e "${green}正在设置 DNS 为 $dns_to_set ($region) ...${reset}"
    cp /etc/resolv.conf /etc/resolv.conf.bak
    echo "nameserver $dns_to_set" > /etc/resolv.conf
    echo -e "${green}DNS 已切换完成${reset}\n"
fi
