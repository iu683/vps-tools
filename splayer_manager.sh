#!/bin/bash
# SPlayer 一键管理脚本

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

IMAGE_NAME="splayer"
CONTAINER_NAME="SPlayer"
PORT=25884

# 获取公网IP
get_ip() {
    curl -s ifconfig.me || curl -s ipinfo.io/ip
}

# 检测 Docker
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}未检测到 Docker，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
    fi
}

# 安装/启动
install() {
    check_docker
    echo -e "${GREEN}开始构建 SPlayer 镜像...${RESET}"
    docker build -t ${IMAGE_NAME} .

    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}检测到旧容器，正在删除...${RESET}"
        docker rm -f ${CONTAINER_NAME}
    fi

    echo -e "${GREEN}启动 SPlayer 容器...${RESET}"
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:${PORT} ${IMAGE_NAME}

    echo -e "${GREEN}SPlayer 已启动！${RESET}"
    echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
}

# 更新
update() {
    echo -e "${GREEN}更新 SPlayer...${RESET}"
    docker rm -f ${CONTAINER_NAME} 2>/dev/null
    docker build --no-cache -t ${IMAGE_NAME} .
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:${PORT} ${IMAGE_NAME}
    echo -e "${GREEN}更新完成！${RESET}"
    echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
}

# 卸载
uninstall() {
    echo -e "${RED}卸载 SPlayer...${RESET}"
    docker rm -f ${CONTAINER_NAME} 2>/dev/null
    docker rmi -f ${IMAGE_NAME} 2>/dev/null
    echo -e "${GREEN}卸载完成${RESET}"
}

# 显示访问地址
show_url() {
    echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
}

# 菜单
menu() {
    echo -e "${GREEN}===== SPlayer 管理脚本 =====${RESET}"
    echo "1. 安装/启动"
    echo "2. 更新"
    echo "3. 卸载"
    echo "4. 显示访问地址"
    echo "0. 退出"
    echo -n "请选择: "
    read -r choice
    case $choice in
        1) install ;;
        2) update ;;
        3) uninstall ;;
        4) show_url ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}" ;;
    esac
}

menu
