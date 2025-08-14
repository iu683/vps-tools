#!/bin/bash
# ========================================
# OCI Helper Docker Compose 管理脚本（带首次密码提示）
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
    echo "3) 查看访问地址"
    echo "4) 查看容器日志"
    echo "5) 退出"
    read -rp "请选择操作 [1-5]: " choice

    case $choice in
        1)
            echo -e "${GREEN}正在安装或更新 OCI Helper 容器...${RESET}"
            bash <(wget -qO- "$INSTALL_SCRIPT_URL")
            echo -e "${CYAN}安装/更新完成，访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"

            # 首次安装检测
            if [ ! -f "$CONFIG_FILE" ]; then
                echo -e "${YELLOW}首次安装，请修改默认账号密码！${RESET}"
                echo -e "配置文件位置: $CONFIG_FILE"
                read -rp "修改完成后是否立即重启容器? [y/N]: " restart_choice
                if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
                    docker restart "$CONTAINER_NAME"
                    echo -e "${GREEN}容器已重启${RESET}"
                fi
            fi
            ;;
        2)
            echo -e "${RED}正在卸载 OCI Helper 容器...${RESET}"
            docker stop "$CONTAINER_NAME" 2>/dev/null
            docker rm "$CONTAINER_NAME" 2>/dev/null
            echo -e "${GREEN}卸载完成${RESET}"
            ;;
        3)
            echo -e "${CYAN}访问地址: ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
            echo -e "${YELLOW}默认账号/密码：yohann / yohann${RESET}"
            ;;
        4)
            echo -e "${YELLOW}容器日志 (${CONTAINER_NAME}):${RESET}"
            docker logs "$CONTAINER_NAME"
            echo -e "\n${YELLOW}如果需要导出日志到文件，可执行:${RESET}"
            echo "docker logs $CONTAINER_NAME >> /app/oci-helper/oci-helper.log"
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
