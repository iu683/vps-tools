#!/bin/bash
# ========================================
# OCI Helper 一键部署 & 管理脚本（彩色菜单版 + docker-compose.yml 内置）
# 作者: Linai Li 专用版
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

APP_NAME="oci-helper"
APP_PORT=8818
APP_DIR="/app/oci-helper"

# ======== docker-compose.yml 内容 ========
compose_file="$APP_DIR/docker-compose.yml"

compose_content='
services:
  watcher:
    image: ghcr.io/yohann0617/oci-helper-watcher:main
    container_name: oci-helper-watcher
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/local/bin/docker-compose:/usr/local/bin/docker-compose
      - /app/oci-helper/docker-compose.yml:/app/oci-helper/docker-compose.yml
      - /app/oci-helper/update_version_trigger.flag:/app/oci-helper/update_version_trigger.flag
      - /app/oci-helper/oci-helper.db:/app/oci-helper/oci-helper.db

  oci-helper:
    image: ghcr.io/yohann0617/oci-helper:master
    container_name: oci-helper
    restart: always
    ports:
      - "127.0.0.1:8818:8818"
    volumes:
      - /app/oci-helper/application.yml:/app/oci-helper/application.yml
      - /app/oci-helper/oci-helper.db:/app/oci-helper/oci-helper.db
      - /app/oci-helper/keys:/app/oci-helper/keys
      - /app/oci-helper/update_version_trigger.flag:/app/oci-helper/update_version_trigger.flag
    networks:
      - app-network
      
  websockify:
    image: ghcr.io/yohann0617/oci-helper-websockify:master
    container_name: websockify
    restart: always
    ports:
      - "127.0.0.1:6080:6080"
    depends_on:
      - oci-helper
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
'

install_or_update() {
    echo -e "${GREEN}开始部署/更新 OCI Helper...${RESET}"
    mkdir -p "$APP_DIR"
    echo "$compose_content" > "$compose_file"
    docker compose -f "$compose_file" pull
    docker compose -f "$compose_file" up -d
    echo -e "${CYAN}部署完成！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):$APP_PORT${RESET}"
    echo -e "默认账号密码: ${YELLOW}yohann / yohann${RESET}"
}

uninstall_app() {
    echo -e "${RED}正在卸载 OCI Helper...${RESET}"
    docker compose -f "$compose_file" down
    echo -e "${GREEN}卸载完成！${RESET}"
}

view_logs() {
    echo -e "${CYAN}正在查看 OCI Helper 日志 (Ctrl+C 退出)...${RESET}"
    docker logs -f $APP_NAME
}

change_password() {
    echo -e "${YELLOW}请输入新账号:${RESET}"
    read NEW_USER
    echo -e "${YELLOW}请输入新密码:${RESET}"
    read NEW_PASS

    echo -e "${GREEN}正在修改容器内配置...${RESET}"
    docker exec -it $APP_NAME sed -i "s/^username:.*/username: $NEW_USER/" /app/oci-helper/application.yml
    docker exec -it $APP_NAME sed -i "s/^password:.*/password: $NEW_PASS/" /app/oci-helper/application.yml
    docker restart $APP_NAME
    echo -e "${CYAN}修改完成！请使用新账号密码登录。${RESET}"
}

while true; do
    echo -e "\n${GREEN}====== OCI Helper 管理菜单 ======${RESET}"
    echo -e "${YELLOW}1.${RESET} 部署/更新 OCI Helper"
    echo -e "${YELLOW}2.${RESET} 卸载 OCI Helper"
    echo -e "${YELLOW}3.${RESET} 查看日志"
    echo -e "${YELLOW}4.${RESET} 修改账号密码"
    echo -e "${YELLOW}0.${RESET} 退出"
    echo -ne "${CYAN}请选择操作: ${RESET}"
    read CHOICE

    case $CHOICE in
        1) install_or_update ;;
        2) uninstall_app ;;
        3) view_logs ;;
        4) change_password ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效的选项，请重新输入！${RESET}" ;;
    esac
done
