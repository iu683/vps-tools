#!/bin/bash
# ========================================
# OCI Docker 管理脚本 (增强菜单版)
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# 默认访问端口
APP_PORT=8088

# 创建目录并进入
DIR="$HOME/oci-start-docker"
mkdir -p "$DIR"
cd "$DIR" || exit

# 下载 docker.sh，如果不存在
if [ ! -f docker.sh ]; then
    echo -e "${CYAN}下载 docker.sh 脚本...${RESET}"
    wget -O docker.sh https://raw.githubusercontent.com/doubleDimple/shell-tools/master/docker.sh
    chmod +x docker.sh
fi

# 获取服务器公网 IP
SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

# 检查端口是否被占用
check_port() {
    while true; do
        if lsof -i:"$APP_PORT" >/dev/null 2>&1; then
            echo -e "${RED}端口 $APP_PORT 已被占用，请输入其他端口:${RESET}"
            read -rp "端口: " APP_PORT
        else
            break
        fi
    done
}

# 菜单
while true; do
    echo -e "\n${YELLOW}==== OCI Docker 管理 ====${RESET}"
    echo "1) 安装应用"
    echo "2) 卸载应用"
    echo "3) 更新 docker.sh 脚本"
    echo "4) 查看访问地址"
    echo "5) 退出"
    read -rp "请选择操作 [1-5]: " choice

    case $choice in
        1)
            check_port
            echo -e "${GREEN}正在安装应用...${RESET}"
            ./docker.sh install
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        2)
            echo -e "${RED}正在卸载应用...${RESET}"
            ./docker.sh uninstall
            ;;
        3)
            echo -e "${CYAN}正在更新 docker.sh 脚本...${RESET}"
            wget -O docker.sh https://raw.githubusercontent.com/doubleDimple/shell-tools/master/docker.sh
            chmod +x docker.sh
            echo -e "${GREEN}更新完成${RESET}"
            ;;
        4)
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        5)
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择${RESET}"
            ;;
    esac
done
