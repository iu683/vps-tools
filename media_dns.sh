#!/bin/bash
# 流媒体解锁 DNS 设置 + 检测脚本

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
)

# 颜色
green="\033[32m"
yellow="\033[33m"
reset="\033[0m"

# 菜单
echo -e "${yellow}请选择要使用的 DNS 区域：${reset}"
select region in "${!dns_list[@]}"; do
    if [[ -n "${dns_list[$region]}" ]]; then
        echo -e "${green}正在设置 DNS 为 ${dns_list[$region]} ($region) ...${reset}"
        cp /etc/resolv.conf /etc/resolv.conf.bak
        echo "nameserver ${dns_list[$region]}" > /etc/resolv.conf
        echo -e "${green}DNS 已切换完成${reset}\n"
        
        # 检测
        echo -e "${yellow}正在检测流媒体解锁情况...${reset}"
        bash <(curl -L -s https://github.com/1-stream/RegionRestrictionCheck/raw/main/check.sh) -M 4
        break
    else
        echo "无效选择，请重新输入。"
    fi
done
