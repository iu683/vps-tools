#!/bin/bash
# ========================================
# STB + MongoDB 一键管理脚本
# 作者: Linai Li
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

COMPOSE_FILE="docker-compose.yml"

# ================== 生成 docker-compose.yml ==================
function generate_compose() {
cat > $COMPOSE_FILE <<EOF
version: '3'
services:
  mongo:
    image: mongo:6
    container_name: stb-mongo
    restart: always
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  stb:
    image: setube/stb:latest
    container_name: stb
    restart: always
    ports:
      - "25519:25519"
    environment:
      MONGO_URL: "mongodb://mongo:27017/stb"
    depends_on:
      - mongo

volumes:
  mongo_data:
EOF
}

# ================== 菜单 ==================
function show_menu() {
    echo -e "${CYAN}================= STB 容器管理 =================${RESET}"
    echo -e "${GREEN}1.${RESET} 启动容器 (STB + MongoDB)"
    echo -e "${GREEN}2.${RESET} 停止容器"
    echo -e "${GREEN}3.${RESET} 重启容器"
    echo -e "${GREEN}4.${RESET} 查看容器状态"
    echo -e "${GREEN}5.${RESET} 卸载容器 (删除容器 + 卷)"
    echo -e "${GREEN}6.${RESET} 更新 STB 容器"
    echo -e "${GREEN}0.${RESET} 退出"
    echo -e "${CYAN}==============================================${RESET}"
}

# ================== 功能 ==================
function start_containers() {
    echo -e "${YELLOW}启动 STB + MongoDB 容器...${RESET}"
    generate_compose
    docker compose up -d
}

function stop_containers() {
    echo -e "${YELLOW}停止容器...${RESET}"
    docker compose down
}

function restart_containers() {
    echo -e "${YELLOW}重启容器...${RESET}"
    docker compose down
    docker compose up -d
}

function status_containers() {
    echo -e "${YELLOW}容器状态:${RESET}"
    docker ps -a | grep -E "stb|stb-mongo"
}

function uninstall_containers() {
    echo -e "${YELLOW}卸载容器及数据卷...${RESET}"
    docker compose down -v
    echo -e "${GREEN}卸载完成${RESET}"
}

function update_stb() {
    echo -e "${YELLOW}更新 STB 镜像并重启容器...${RESET}"
    docker pull setube/stb:latest
    docker compose up -d stb
    echo -e "${GREEN}更新完成${RESET}"
}

# ================== 主循环 ==================
while true; do
    show_menu
    read -p "请输入选项: " choice
    case $choice in
        1) start_containers ;;
        2) stop_containers ;;
        3) restart_containers ;;
        4) status_containers ;;
        5) uninstall_containers ;;
        6) update_stb ;;
        0) echo -e "${GREEN}退出脚本${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入${RESET}" ;;
    esac
done
