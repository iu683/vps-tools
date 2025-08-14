#!/bin/bash

# ========================================
# Nexus Terminal 一键管理脚本（自动检测 Docker + 首次部署 + 卸载）
# ========================================

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker 未安装！请先安装 Docker。${RESET}"
    echo -e "${YELLOW}安装命令示例（Ubuntu/Debian）:${RESET}"
    echo "sudo apt update && sudo apt install -y docker.io docker-compose"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose 未安装或版本不支持！${RESET}"
    echo -e "${YELLOW}请参考官方文档安装 Docker Compose V2:${RESET}"
    echo "https://docs.docker.com/compose/install/"
    exit 1
fi

# 工作目录
WORKDIR="$HOME/nexus-terminal"

# 首次部署检测
first_run=false
if [ ! -d "$WORKDIR" ]; then
    first_run=true
    mkdir -p "$WORKDIR"
    echo -e "${GREEN}已创建工作目录：$WORKDIR${RESET}"
fi

cd "$WORKDIR" || exit

# 首次运行自动下载 docker-compose.yml 和 .env
if [ "$first_run" = true ]; then
    echo -e "${BLUE}首次运行：下载 docker-compose.yml 和 .env 文件...${RESET}"
    wget -q https://raw.githubusercontent.com/Heavrnl/nexus-terminal/refs/heads/main/docker-compose.yml -O docker-compose.yml
    wget -q https://raw.githubusercontent.com/Heavrnl/nexus-terminal/refs/heads/main/.env -O .env

    echo -e "${GREEN}首次运行：启动服务中...${RESET}"
    docker compose up -d
    echo -e "${GREEN}服务已启动，访问端口请查看 .env 文件配置${RESET}"
fi

# 菜单函数
show_menu() {
    echo -e "${CYAN}================ Nexus Terminal 管理菜单 ================${RESET}"
    echo -e "${YELLOW}1.${RESET} 启动服务"
    echo -e "${YELLOW}2.${RESET} 停止服务"
    echo -e "${YELLOW}3.${RESET} 更新服务"
    echo -e "${YELLOW}4.${RESET} 查看日志"
    echo -e "${YELLOW}5.${RESET} 卸载服务"
    echo -e "${YELLOW}6.${RESET} 退出"
    echo -e "${CYAN}======================================================${RESET}"
}

# 菜单循环
while true; do
    show_menu
    read -rp "请选择操作 [1-6]: " choice
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
            read -rp "确认卸载服务并删除所有数据吗？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${RED}卸载中...${RESET}"
                docker compose down --rmi all --volumes --remove-orphans
                cd "$HOME" || exit
                rm -rf "$WORKDIR"
                echo -e "${GREEN}服务已卸载，工作目录已删除${RESET}"
                exit 0
            else
                echo -e "${YELLOW}取消卸载${RESET}"
            fi
            ;;
        6)
            echo -e "${YELLOW}退出脚本${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}输入错误，请重新选择${RESET}"
            ;;
    esac
done
