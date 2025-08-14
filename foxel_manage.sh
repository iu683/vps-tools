#!/bin/bash
# ========================================
# Foxel Docker 管理脚本
# 作者：Linai Li
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

BASE_DIR="$PWD"
UPLOADS_DIR="${BASE_DIR}/uploads"
DB_DIR="${BASE_DIR}/db"
COMPOSE_FILE="${BASE_DIR}/compose.yaml"

# 一键部署
deploy_foxel() {
    echo -e "${YELLOW}下载 compose.yaml 文件...${RESET}"
    curl -O https://raw.githubusercontent.com/DrizzleTime/Foxel/master/compose.yaml

    echo -e "${YELLOW}创建数据目录...${RESET}"
    mkdir -p "${UPLOADS_DIR}" "${DB_DIR}"

    echo -e "${YELLOW}设置目录权限...${RESET}"
    chmod 777 "${UPLOADS_DIR}"
    chmod 700 "${DB_DIR}"

    echo -e "${YELLOW}启动所有容器...${RESET}"
    docker compose up -d

    echo -e "${GREEN}Foxel Docker 已部署完成！${RESET}"
    docker compose ps
}

# 启动容器
start_foxel() {
    docker compose start
    echo -e "${GREEN}Foxel 容器已启动${RESET}"
}

# 停止容器
stop_foxel() {
    docker compose stop
    echo -e "${YELLOW}Foxel 容器已停止${RESET}"
}

# 重启容器
restart_foxel() {
    docker compose restart
    echo -e "${GREEN}Foxel 容器已重启${RESET}"
}

# 查看日志
logs_foxel() {
    docker compose logs -f
}

# 卸载容器
uninstall_foxel() {
    docker compose down
    echo -e "${YELLOW}是否删除数据目录？[y/N]${RESET}"
    read -r del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm -rf "${UPLOADS_DIR}" "${DB_DIR}"
        echo -e "${RED}数据目录已删除${RESET}"
    fi
    echo -e "${GREEN}Foxel Docker 已卸载${RESET}"
}

# 菜单
menu() {
    clear
    echo -e "${CYAN}==== Foxel Docker 管理菜单 ====${RESET}"
    echo -e "1. 一键部署 & 启动容器"
    echo -e "2. 启动容器"
    echo -e "3. 停止容器"
    echo -e "4. 重启容器"
    echo -e "5. 查看日志"
    echo -e "6. 卸载容器"
    echo -e "0. 退出"
    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read -r choice
    case "$choice" in
        1) deploy_foxel ;;
        2) start_foxel ;;
        3) stop_foxel ;;
        4) restart_foxel ;;
        5) logs_foxel ;;
        6) uninstall_foxel ;;
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
