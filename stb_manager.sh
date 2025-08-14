#!/bin/bash
# ========================================
# STB 容器管理脚本（卸载/更新分开）
# 作者: Linai Li
# ========================================

# ================== 颜色 ==================
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# ================== 镜像信息 ==================
DOCKERHUB_IMAGE="setube/stb:latest"
GHCR_IMAGE="ghcr.io/setube/stb:latest"
CONTAINER_NAME="stb"
PORT=25519

# ================== 菜单 ==================
function show_menu() {
    echo -e "${CYAN}================= STB 容器管理 =================${RESET}"
    echo -e "${GREEN}1.${RESET} 拉取 DockerHub 镜像"
    echo -e "${GREEN}2.${RESET} 拉取 GitHub 镜像"
    echo -e "${GREEN}3.${RESET} 构建本地镜像 (Dockerfile)"
    echo -e "${GREEN}4.${RESET} 运行容器"
    echo -e "${GREEN}5.${RESET} 查看容器状态"
    echo -e "${GREEN}6.${RESET} 停止容器"
    echo -e "${GREEN}7.${RESET} 删除容器"
    echo -e "${GREEN}8.${RESET} 卸载容器 (删除容器 + 镜像)"
    echo -e "${GREEN}9.${RESET} 更新容器 (拉取最新镜像并重启)"
    echo -e "${GREEN}0.${RESET} 退出"
    echo -e "${CYAN}================================================${RESET}"
}

# ================== 功能 ==================
function pull_dockerhub() {
    echo -e "${YELLOW}正在拉取 DockerHub 镜像...${RESET}"
    docker pull $DOCKERHUB_IMAGE
}

function pull_ghcr() {
    echo -e "${YELLOW}正在拉取 GitHub 镜像...${RESET}"
    docker pull $GHCR_IMAGE
}

function build_image() {
    echo -e "${YELLOW}正在构建本地镜像...${RESET}"
    docker build -t $DOCKERHUB_IMAGE .
    docker build -t $GHCR_IMAGE .
}

function run_container() {
    echo -e "${YELLOW}正在运行容器...${RESET}"
    if [ $(docker ps -a -q -f name=$CONTAINER_NAME) ]; then
        echo -e "${RED}容器已存在，请先停止或删除旧容器${RESET}"
    else
        docker run -d --name $CONTAINER_NAME -p $PORT:$PORT $DOCKERHUB_IMAGE
        echo -e "${GREEN}容器已启动，访问端口: $PORT${RESET}"
    fi
}

function status_container() {
    echo -e "${YELLOW}容器状态:${RESET}"
    docker ps -a | grep $CONTAINER_NAME
}

function stop_container() {
    echo -e "${YELLOW}停止容器...${RESET}"
    docker stop $CONTAINER_NAME
}

function remove_container() {
    echo -e "${YELLOW}删除容器...${RESET}"
    docker rm $CONTAINER_NAME
}

# ================== 卸载 ==================
function uninstall_container() {
    echo -e "${YELLOW}开始卸载容器...${RESET}"

    # 停止容器
    if [ $(docker ps -q -f name=$CONTAINER_NAME) ]; then
        echo -e "${BLUE}停止容器...${RESET}"
        docker stop $CONTAINER_NAME
    fi

    # 删除容器
    if [ $(docker ps -a -q -f name=$CONTAINER_NAME) ]; then
        echo -e "${BLUE}删除容器...${RESET}"
        docker rm $CONTAINER_NAME
    fi

    # 删除镜像
    if [ $(docker images -q $DOCKERHUB_IMAGE) ]; then
        echo -e "${BLUE}删除 DockerHub 镜像...${RESET}"
        docker rmi $DOCKERHUB_IMAGE
    fi
    if [ $(docker images -q $GHCR_IMAGE) ]; then
        echo -e "${BLUE}删除 GHCR 镜像...${RESET}"
        docker rmi $GHCR_IMAGE
    fi

    echo -e "${GREEN}卸载完成${RESET}"
}

# ================== 更新 ==================
function update_container() {
    echo -e "${YELLOW}开始更新容器...${RESET}"

    # 停止并删除已有容器
    if [ $(docker ps -a -q -f name=$CONTAINER_NAME) ]; then
        echo -e "${BLUE}停止并删除旧容器...${RESET}"
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi

    # 拉取最新镜像
    echo -e "${GREEN}拉取最新 DockerHub 镜像...${RESET}"
    docker pull $DOCKERHUB_IMAGE

    # 启动容器
    echo -e "${GREEN}启动新容器...${RESET}"
    docker run -d --name $CONTAINER_NAME -p $PORT:$PORT $DOCKERHUB_IMAGE
    echo -e "${GREEN}更新完成，容器已启动${RESET}"
}

# ================== 主循环 ==================
while true; do
    show_menu
    read -p "请输入选项: " choice
    case $choice in
        1) pull_dockerhub ;;
        2) pull_ghcr ;;
        3) build_image ;;
        4) run_container ;;
        5) status_container ;;
        6) stop_container ;;
        7) remove_container ;;
        8) uninstall_container ;;
        9) update_container ;;
        0) echo -e "${GREEN}退出脚本${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入${RESET}" ;;
    esac
done
