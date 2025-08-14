#!/bin/bash
# ========================================
# OCI Docker 管理脚本 (无 docker.sh，固定端口9856，简化版)
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

APP_PORT=9856
CONTAINER_NAME="oci-start"
IMAGE_NAME="doubleDimple/oci-start:latest"

# 创建目录
DIR="$HOME/oci-start-docker"
mkdir -p "$DIR"
cd "$DIR" || exit

# 获取服务器公网 IP
SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

# 检查端口是否被占用
check_port() {
    if lsof -i:"$APP_PORT" >/dev/null 2>&1; then
        echo -e "${RED}端口 $APP_PORT 已被占用，请先释放端口再操作${RESET}"
        exit 1
    fi
}

# 菜单
while true; do
    echo -e "\n${YELLOW}==== OCI Docker 容器管理 ====${RESET}"
    echo "1) 安装容器"
    echo "2) 卸载容器"
    echo "3) 更新容器"
    echo "4) 查看访问地址"
    echo "5) 查看容器日志"
    echo "6) 退出"
    read -rp "请选择操作 [1-6]: " choice

    case $choice in
        1)
            check_port
            echo -e "${GREEN}正在安装容器...${RESET}"
            docker pull "$IMAGE_NAME"
            docker run -d --name "$CONTAINER_NAME" -p "$APP_PORT:$APP_PORT" "$IMAGE_NAME"
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        2)
            echo -e "${RED}正在卸载容器...${RESET}"
            docker stop "$CONTAINER_NAME" 2>/dev/null
            docker rm "$CONTAINER_NAME" 2>/dev/null
            ;;
        3)
            echo -e "${CYAN}正在更新容器...${RESET}"
            docker pull "$IMAGE_NAME"
            docker stop "$CONTAINER_NAME" 2>/dev/null
            docker rm "$CONTAINER_NAME" 2>/dev/null
            docker run -d --name "$CONTAINER_NAME" -p "$APP_PORT:$APP_PORT" "$IMAGE_NAME"
            ;;
        4)
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        5)
            echo -e "${YELLOW}容器日志 (${CONTAINER_NAME}):${RESET}"
            docker logs "$CONTAINER_NAME"
            ;;
        6)
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择${RESET}"
            ;;
    esac
done
