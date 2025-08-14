#!/bin/bash
# ========================================
# OCI Docker 管理脚本 (依赖 docker.sh，固定端口9856)
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

APP_PORT=9856
CONTAINER_NAME="oci-start"
SCRIPT_URL="https://raw.githubusercontent.com/doubleDimple/shell-tools/master/docker.sh"
SCRIPT_FILE="docker.sh"

# 创建目录并进入
DIR="$HOME/oci-start-docker"
mkdir -p "$DIR"
cd "$DIR" || exit

# 下载 docker.sh，如果不存在或更新
download_script() {
    echo -e "${CYAN}正在下载/更新 docker.sh 脚本...${RESET}"
    wget -O "$SCRIPT_FILE" "$SCRIPT_URL"
    chmod +x "$SCRIPT_FILE"
}

# 获取服务器公网 IP
SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

# 检查端口占用
check_port() {
    if lsof -i:"$APP_PORT" >/dev/null 2>&1; then
        echo -e "${RED}端口 $APP_PORT 已被占用，请先释放端口再操作${RESET}"
        exit 1
    fi
}

# 菜单
while true; do
    echo -e "\n${YELLOW}==== OCI Docker 管理 (依赖 docker.sh) ====${RESET}"
    echo "1) 安装应用"
    echo "2) 卸载应用"
    echo "3) 更新 docker.sh 脚本"
    echo "4) 查看访问地址"
    echo "5) 查看容器日志"
    echo "6) 退出"
    read -rp "请选择操作 [1-6]: " choice

    case $choice in
        1)
            check_port
            download_script
            echo -e "${GREEN}正在安装应用...${RESET}"
            ./"$SCRIPT_FILE" install
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        2)
            download_script
            echo -e "${RED}正在卸载应用...${RESET}"
            ./"$SCRIPT_FILE" uninstall
            ;;
        3)
            download_script
            echo -e "${GREEN}docker.sh 脚本更新完成${RESET}"
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
