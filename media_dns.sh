#!/bin/bash
# 流媒体解锁 DNS 快捷切换脚本（无检测）

# DNS 列表
declare -A dns_list=(
  ["Default"]="154.83.83.83"
  ["HK"]="154.83.83.84"
  ["JP"]="154.83.83.85"
  ["TW"]="154.83.83.86"
  ["SG"]="154.83.83.87"
  ["US"]="154.83.83.88"
  ["UK"]="154.83.83.89"
  ["DE"]="154.83.83.90"
  ["RFC"]="22.22.22.22"
  ["Custom"]="custom"
)

# 颜色
green="\033[32m"
yellow="\033[33m"
reset="\033[0m"

# 菜单
echo -e "${yellow}请选择要使用的 DNS 区域：${reset}"
select region in "${!dns_list[@]}"; do
    if [[ "$region" == "Custom" ]]; then
        read -p "请输入自定义 DNS IP 地址: " custom_dns
        dns_to_set="$custom_dns"
    elif [[ -n "${dns_list[$region]}" ]]; then
        dns_to_set="${dns_list[$region]}"
    else
        echo "无效选择，请重新输入。"
        continue
    fi

    if [[ -n "$dns_to_set" ]]; then
        echo -e "${green}正在设置 DNS 为 $dns_to_set ($region) ...${reset}"
        cp /etc/resolv.conf /etc/resolv.conf.bak
        echo "nameserver $dns_to_set" > /etc/resolv.conf
        echo -e "${green}DNS 已切换完成${reset}\n"
        break
    fi
done
