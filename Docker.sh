#!/bin/bash
# ========================================
# VPS 工具箱 - Docker & 网络管理（增强版，无保存iptables）
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# 检测是否在中国大陆
check_china() {
    if ping -c1 -W1 www.baidu.com >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 安装 Docker
install_docker() {
    echo -e "${BLUE}检测网络环境...${RESET}"
    if check_china; then
        echo -e "${GREEN}检测到中国大陆，使用阿里云源安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    else
        echo -e "${GREEN}检测到非中国大陆，使用官方源安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | bash
    fi
    systemctl enable docker
    systemctl start docker
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}Docker 已成功启动！${RESET}"
        docker version
    else
        echo -e "${RED}Docker 启动失败，请检查系统日志。${RESET}"
    fi
}

# 卸载 Docker
uninstall_docker() {
    echo -e "${YELLOW}正在卸载 Docker...${RESET}"
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    apt purge -y docker* containerd runc 2>/dev/null
    rm -rf /var/lib/docker /etc/docker
    echo -e "${GREEN}Docker 已卸载${RESET}"
}

# 更新 Docker
update_docker() {
    echo -e "${BLUE}正在更新 Docker...${RESET}"
    apt update && apt upgrade -y docker-ce docker-ce-cli containerd.io
    echo -e "${GREEN}Docker 更新完成${RESET}"
}

# 开放所有端口
open_all_ports() {
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F
    echo -e "${GREEN}所有端口已开放${RESET}"
}

# IPv6 管理
enable_ipv6() {
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
    sysctl -w net.ipv6.conf.default.disable_ipv6=0
    echo -e "${GREEN}IPv6 已启用${RESET}"
}

disable_ipv6() {
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
    echo -e "${GREEN}IPv6 已禁用${RESET}"
}

# 容器管理
list_containers() {
    docker ps -a
}

start_container() {
    read -p "请输入要启动的容器ID或名称: " id
    docker start "$id"
}

stop_container() {
    read -p "请输入要停止的容器ID或名称: " id
    docker stop "$id"
}

remove_container() {
    read -p "请输入要删除的容器ID或名称: " id
    docker rm "$id"
}

# 镜像管理
list_images() {
    docker images
}

remove_image() {
    read -p "请输入要删除的镜像ID或名称: " id
    docker rmi "$id"
}

# Docker 清理
clean_docker() {
    echo -e "${YELLOW}正在清理未使用的 Docker 资源...${RESET}"
    docker container prune -f
    docker image prune -af
    docker volume prune -f
    docker network prune -f
    echo -e "${GREEN}Docker 清理完成${RESET}"
}

# 菜单
while true; do
    clear
    echo -e "${CYAN}====== VPS 工具箱 ======${RESET}"
    echo "1. 安装 Docker"
    echo "2. 卸载 Docker"
    echo "3. 更新 Docker"
    echo "4. 开放所有端口"
    echo "5. 启用 IPv6"
    echo "6. 禁用 IPv6"
    echo "7. 列出所有容器"
    echo "8. 启动容器"
    echo "9. 停止容器"
    echo "10. 删除容器"
    echo "11. 列出所有镜像"
    echo "12. 删除镜像"
    echo "13. 一键清理未使用的容器/镜像/卷/网络"
    echo "0. 退出"
    read -p "请选择: " choice

    case "$choice" in
        1) install_docker ;;
        2) uninstall_docker ;;
        3) update_docker ;;
        4) open_all_ports ;;
        5) enable_ipv6 ;;
        6) disable_ipv6 ;;
        7) list_containers ;;
        8) start_container ;;
        9) stop_container ;;
        10) remove_container ;;
        11) list_images ;;
        12) remove_image ;;
        13) clean_docker ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; sleep 1 ;;
    esac
    echo
    read -p "按回车键返回菜单..."
done
