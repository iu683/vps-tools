#!/bin/bash
# ========================================
# OCI Helper 一键部署 & 管理脚本（彩色菜单版）
# 作者: Linai Li 专用版
# ========================================

# ======== 颜色定义 ========
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# ======== 变量定义 ========
APP_NAME="oci-helper"
APP_PORT=8818
INSTALL_SCRIPT_URL="https://github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh"

# ======== 功能函数 ========

install_or_update() {
    echo -e "${GREEN}开始安装/更新 $APP_NAME ...${RESET}"
    bash <(wget -qO- "$INSTALL_SCRIPT_URL")
    echo -e "${CYAN}安装/更新完成！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):$APP_PORT${RESET}"
    echo -e "默认账号密码: ${YELLOW}yohann / yohann${RESET}"
}

uninstall_app() {
    echo -e "${RED}正在卸载 $APP_NAME ...${RESET}"
    docker rm -f $APP_NAME 2>/dev/null
    echo -e "${GREEN}卸载完成！${RESET}"
}

view_logs() {
    echo -e "${CYAN}正在查看 $APP_NAME 日志 (按 Ctrl+C 退出)...${RESET}"
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

# ======== 主菜单 ========
while true; do
    echo -e "\n${GREEN}====== OCI Helper 管理菜单 ======${RESET}"
    echo -e "${YELLOW}1.${RESET} 安装/更新 OCI Helper"
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
