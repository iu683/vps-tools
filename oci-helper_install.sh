#!/bin/bash
# ========================================
# oci-helper 菜单式管理脚本 (增强版)
# 作者: Linai Li (改编 by ChatGPT)
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

CONFIG_FILE="/app/oci-helper/application.yml"
INSTALL_URL="https://github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh"
CONTAINER_NAME="oci-helper"

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}错误: 未检测到 Docker，请先安装 Docker！${RESET}"
        exit 1
    fi
}

# 安装 oci-helper
install_oci() {
    echo -e "${CYAN}正在安装 oci-helper...${RESET}"
    bash <(wget -qO- "$INSTALL_URL")
    echo -e "${GREEN}安装完成！${RESET}"
}

# 修改配置
edit_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}配置文件不存在: $CONFIG_FILE${RESET}"
        echo -e "${YELLOW}请先安装 oci-helper 再修改配置${RESET}"
        return
    fi
    nano "$CONFIG_FILE"
    echo -e "${GREEN}配置已修改${RESET}"
}

# 重启容器
restart_container() {
    docker restart "$CONTAINER_NAME"
    echo -e "${GREEN}容器已重启${RESET}"
}

# 卸载 oci-helper
uninstall_oci() {
    echo -e "${YELLOW}正在停止并删除容器...${RESET}"
    docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
    echo -e "${YELLOW}正在删除镜像...${RESET}"
    docker rmi "$(docker images --format '{{.Repository}}:{{.Tag}}' | grep oci-helper)"
    echo -e "${GREEN}卸载完成${RESET}"
}

# 更新 oci-helper
update_oci() {
    echo -e "${CYAN}正在更新 oci-helper 到最新版本...${RESET}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    bash <(wget -qO- "$INSTALL_URL")
    echo -e "${GREEN}更新完成！${RESET}"
}

# 查看日志
view_logs() {
    echo -e "${CYAN}按 Ctrl+C 停止查看日志${RESET}"
    docker logs -f "$CONTAINER_NAME"
}

# 菜单
menu() {
    clear
    echo -e "${CYAN}====== oci-helper 菜单式管理 ======${RESET}"
    echo -e "1. 安装 oci-helper"
    echo -e "2. 修改配置文件"
    echo -e "3. 重启容器"
    echo -e "4. 卸载 oci-helper"
    echo -e "5. 更新 oci-helper"
    echo -e "6. 查看运行日志"
    echo -e "0. 退出"
    echo -ne "${YELLOW}请选择: ${RESET}"
    read -r choice

    case $choice in
        1) install_oci ;;
        2) edit_config ;;
        3) restart_container ;;
        4) uninstall_oci ;;
        5) update_oci ;;
        6) view_logs ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}" ;;
    esac

    echo -e "${YELLOW}按任意键返回菜单...${RESET}"
    read -n 1
    menu
}

# 主程序
check_docker
menu
