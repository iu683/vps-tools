#!/bin/bash
# ========================================
# Docker qBittorrent 管理脚本（使用 docker compose）
# 作者：Linai Li
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

BASE_DIR="/data/docker/qbittorrent"
CONFIG_DIR="${BASE_DIR}/config"
DOWNLOAD_DIR="${BASE_DIR}/downloads"
COMPOSE_FILE="${BASE_DIR}/docker-compose.yml"
CONTAINER_NAME="qbittorrent"

# 部署容器
deploy_qbittorrent() {
    echo -e "${YELLOW}创建目录...${RESET}"
    mkdir -p "${CONFIG_DIR}" "${DOWNLOAD_DIR}"
    cd "${BASE_DIR}" || return

    echo -e "${YELLOW}生成 docker-compose.yml 文件...${RESET}"
    cat > "${COMPOSE_FILE}" <<EOF
version: '3'

services:
  qbittorrent:
    image: linuxserver/qbittorrent
    container_name: ${CONTAINER_NAME}
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - UMASK_SET=022
    ports:
      - "6881:6881"
      - "6881:6881/udp"
      - "8080:8080"
    volumes:
      - ./config:/config
      - ./downloads:/downloads
    restart: unless-stopped
EOF

    echo -e "${YELLOW}启动容器...${RESET}"
    docker compose up -d

    echo -e "${GREEN}qBittorrent Docker 容器已部署并启动！${RESET}"
    echo -e "${CYAN}WebUI 地址: http://$(hostname -I | awk '{print $1}'):8080${RESET}"
}

# 启动容器
start_qbittorrent() {
    cd "${BASE_DIR}" || return
    docker compose start
    echo -e "${GREEN}qBittorrent 已启动${RESET}"
}

# 停止容器
stop_qbittorrent() {
    cd "${BASE_DIR}" || return
    docker compose stop
    echo -e "${YELLOW}qBittorrent 已停止${RESET}"
}

# 重启容器
restart_qbittorrent() {
    cd "${BASE_DIR}" || return
    docker compose restart
    echo -e "${GREEN}qBittorrent 已重启${RESET}"
}

# 查看日志
logs_qbittorrent() {
    cd "${BASE_DIR}" || return
    docker compose logs -f
}

# 卸载容器
uninstall_qbittorrent() {
    cd "${BASE_DIR}" || return
    docker compose down
    echo -e "${YELLOW}是否删除配置和下载目录？[y/N]${RESET}"
    read -r del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm -rf "${BASE_DIR}"
        echo -e "${RED}配置和下载数据已删除${RESET}"
    fi
    echo -e "${GREEN}qBittorrent Docker 已卸载${RESET}"
}

# 菜单
menu() {
    clear
    echo -e "${CYAN}==== Docker qBittorrent 管理菜单 ====${RESET}"
    echo -e "1. 一键部署 & 启动 qBittorrent"
    echo -e "2. 启动 qBittorrent"
    echo -e "3. 停止 qBittorrent"
    echo -e "4. 重启 qBittorrent"
    echo -e "5. 查看日志"
    echo -e "6. 卸载 qBittorrent"
    echo -e "0. 退出"
    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read -r choice
    case "$choice" in
        1) deploy_qbittorrent ;;
        2) start_qbittorrent ;;
        3) stop_qbittorrent ;;
        4) restart_qbittorrent ;;
        5) logs_qbittorrent ;;
        6) uninstall_qbittorrent ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
}

# 循环菜单
while true; do
    menu
    echo -e "${YELLOW}按回车键继续...${RESET}"
    read -r
done
