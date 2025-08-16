#!/bin/bash
# VPS 网络测试工具 - Ping + 路由（带颜色输出）

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 检查必要命令是否存在
for cmd in ping traceroute; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${YELLOW}$cmd 未安装，正在安装...${RESET}"
        if command -v apt &>/dev/null; then
            apt update && apt install -y $cmd
        elif command -v yum &>/dev/null; then
            yum install -y $cmd
        else
            echo -e "${RED}无法自动安装 $cmd，请手动安装${RESET}"
            exit 1
        fi
    fi
done

# 输入目标
read -p "$(echo -e ${YELLOW}请输入要测试的域名或IP: ${RESET})" target

echo -e "\n${GREEN}==== 开始 Ping 测试 ====${RESET}"
ping -c 4 $target

echo -e "\n${GREEN}==== 开始路由跟踪 (traceroute) ====${RESET}"
traceroute $target

echo -e "\n${GREEN}==== 测试完成 ====${RESET}"
