#!/bin/bash

# ========================================
# Nexus Terminal 一键管理脚本
# ========================================

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# 工作目录
WORKDIR="$HOME/nexus-terminal"

# 检查工作目录
if [ ! -d "$WORKDIR" ]; then
    mkdir -p "$WORKDIR"
    cd "$WORKDIR" || exit
    echo -e "${GREEN}已创建工作目录：$WORKDIR${RESET}"

    # 下载 docker-compose 文件和 .env
    wget https://raw.githubusercontent.com/Heavrnl/nexus-terminal/refs/heads/main/docker-compose.yml -O docker-compose.yml
    wget https://raw.githubusercontent.com/Heavrnl/nexus-terminal/refs/heads/main/.env -O .env
fi

cd "$WORKDIR" || exit

# 菜单函数
show_menu() {
    echo -e "${CYAN}================ Nexus Terminal 管理菜单 ================${RESET}"
    echo -e "${YELLOW}1.${RESET} 启动服务"
    echo -e "${YELLOW}2.${RESET} 停止服务"
    echo -e "${YELLOW}3.${RESET} 更新服务"
    echo -e "${YELLOW}4.${RESET} 查看日志"
    echo -e "${YELLOW}5.${RESET} 退出"
    echo -e "${CYAN}======================================================${RESET}"
}

while true; do
    show_menu
    read -rp "请选择操作 [1-5]: " choice
    case $choice in
        1)
            echo -e "${GREEN}启动服务中...${RESET}"
            docker compose up -d
            echo -e "${GREEN}服务已启动${RESET}"
            ;;
        2)
            echo -e "${RED}停止服务中...${RESET}"
            docker compose down
            echo -e "${RED}服务已停止${RESET}"
            ;;
        3)
            echo -e "${BLUE}更新服务中...${RESET}"
            docker compose down
            docker compose pull
            docker compose up -d
            echo -e "${GREEN}服务已更新并启动${RESET}"
            ;;
        4)
            echo -e "${CYAN}显示日志（Ctrl+C 退出）${RESET}"
            docker compose logs -f
            ;;
        5)
            echo -e "${YELLOW}退出脚本${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}输入错误，请重新选择${RESET}"
            ;;
    esac
done
