#!/bin/bash
# ========================================
# OCI Helper Docker Compose 管理脚本（带修改密码功能）
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

APP_PORT=8818
CONTAINER_NAME="oci-helper"
INSTALL_SCRIPT_URL="https://github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh"
CONFIG_FILE="/app/oci-helper/application.yml"

# 获取服务器公网 IP
SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

# 检查容器是否已存在
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"
}

# 菜单
while true; do
    echo -e "\n${YELLOW}==== OCI Helper 管理 ====${RESET}"
    echo "1) 安装或更新容器"
    echo "2) 卸载容器"
    echo "3) 修改默认账号密码"
    echo "4) 查看访问地址"
    echo "5) 查看容器日志"
    echo "6) 退出"
    read -rp "请选择操作 [1-6]: " choice

    case $choice in
        1)
            echo -e "${GREEN}正在安装或更新 OCI Helper 容器...${RESET}"
            bash <(wget -qO- "$INSTALL_SCRIPT_URL")
            echo -e "${CYAN}安装/更新完成，访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        2)
            echo -e "${RED}正在卸载 OCI Helper 容器...${RESET}"
            docker stop "$CONTAINER_NAME" 2>/dev/null
            docker rm "$CONTAINER_NAME" 2>/dev/null
            echo -e "${GREEN}卸载完成${RESET}"
            ;;
        3)
            if [ ! -f "$CONFIG_FILE" ]; then
                echo -e "${RED}配置文件不存在: $CONFIG_FILE${RESET}"
                echo "请先安装容器"
                continue
            fi
            read -rp "请输入新的账号: " new_user
            read -rsp "请输入新的密码: " new_pass
            echo
            # 修改 application.yml 中的账号和密码配置
            sed -i "s/^username:.*$/username: $new_user/" "$CONFIG_FILE"
            sed -i "s/^password:.*$/password: $new_pass/" "$CONFIG_FILE"
            echo -e "${GREEN}账号密码已修改，正在重启容器...${RESET}"
            docker restart "$CONTAINER_NAME"
            echo -e "${CYAN}容器已重启完成，新的账号密码生效${RESET}"
            ;;
        4)
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            ;;
        5)
            echo -e "${YELLOW}容器日志 (${CONTAINER_NAME}):${RESET}"
            docker logs "$CONTAINER_NAME"
            echo -e "\n${YELLOW}如果需要导出日志到文件，可执行:${RESET}"
            echo "docker logs $CONTAINER_NAME >> /app/oci-helper/oci-helper.log"
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
