#!/bin/bash
# ========================================
# qBittorrent-Nox 一键管理脚本（增强版）
# 新增功能：重置密码 & 修改 WebUI 端口和用户名
# 作者：Linai Li
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

SERVICE_NAME="qbittorrent"
CONFIG_DIR="${HOME}/.config/qBittorrent"
CONF_FILE="${CONFIG_DIR}/qBittorrent.conf"

# 部署 qBittorrent-Nox
install_qbittorrent() {
    echo -e "${YELLOW}更新软件包列表...${RESET}"
    sudo apt update
    echo -e "${YELLOW}安装 qBittorrent-Nox...${RESET}"
    sudo apt install -y qbittorrent-nox

    echo -e "${YELLOW}创建 systemd 服务文件...${RESET}"
    sudo tee /etc/systemd/system/qbittorrent.service > /dev/null <<EOF
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
User=root
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start qbittorrent
    sudo systemctl enable qbittorrent

    echo -e "${GREEN}qBittorrent-Nox 安装完成并已启动!${RESET}"
    echo -e "${CYAN}WebUI 访问地址: http://$(hostname -I | awk '{print $1}'):8080${RESET}"
    echo -e "${YELLOW}默认用户名: admin，密码留空（首次登录请留空）${RESET}"
}

# 启动服务
start_qbittorrent() {
    sudo systemctl start ${SERVICE_NAME}
    echo -e "${GREEN}qBittorrent 已启动${RESET}"
}

# 停止服务
stop_qbittorrent() {
    sudo systemctl stop ${SERVICE_NAME}
    echo -e "${YELLOW}qBittorrent 已停止${RESET}"
}

# 重启服务
restart_qbittorrent() {
    sudo systemctl restart ${SERVICE_NAME}
    echo -e "${GREEN}qBittorrent 已重启${RESET}"
}

# 查看日志
logs_qbittorrent() {
    sudo journalctl -u ${SERVICE_NAME} -f
}

# 卸载服务
uninstall_qbittorrent() {
    sudo systemctl stop ${SERVICE_NAME}
    sudo systemctl disable ${SERVICE_NAME}
    sudo rm -f /etc/systemd/system/${SERVICE_NAME}.service
    sudo systemctl daemon-reload
    echo -e "${YELLOW}是否删除 qBittorrent 配置和下载数据？[y/N]${RESET}"
    read -r del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm -rf "${CONFIG_DIR}"
        echo -e "${RED}配置已删除${RESET}"
    fi
    echo -e "${GREEN}qBittorrent 已卸载${RESET}"
}

# 重置 WebUI 密码（删除配置文件）
reset_webui_password() {
    echo -e "${YELLOW}确定要重置 WebUI 密码吗？这将清空配置文件！[y/N]${RESET}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sudo systemctl stop ${SERVICE_NAME}
        rm -rf "${CONFIG_DIR}"
        sudo systemctl start ${SERVICE_NAME}
        echo -e "${GREEN}已重置 WebUI 密码！首次登录用户名: admin，密码留空${RESET}"
    else
        echo -e "${CYAN}已取消重置${RESET}"
    fi
}

# 修改 WebUI 端口和用户名
modify_webui_settings() {
    if [[ ! -f "${CONF_FILE}" ]]; then
        echo -e "${RED}配置文件不存在，请先启动一次 qBittorrent-Nox${RESET}"
        return
    fi

    echo -ne "${YELLOW}请输入新的 WebUI 端口（回车保留原值）: ${RESET}"
    read -r new_port
    echo -ne "${YELLOW}请输入新的 WebUI 用户名（回车保留原值）: ${RESET}"
    read -r new_user

    # 使用 sed 修改配置文件
    if [[ -n "$new_port" ]]; then
        sed -i "s/^WebUI\\\Port=.*/WebUI\\Port=${new_port}/" "${CONF_FILE}" || \
        echo "WebUI\\Port=${new_port}" >> "${CONF_FILE}"
        echo -e "${GREEN}已修改 WebUI 端口为: ${new_port}${RESET}"
    fi

    if [[ -n "$new_user" ]]; then
        sed -i "s/^WebUI\\\Username=.*/WebUI\\Username=${new_user}/" "${CONF_FILE}" || \
        echo "WebUI\\Username=${new_user}" >> "${CONF_FILE}"
        echo -e "${GREEN}已修改 WebUI 用户名为: ${new_user}${RESET}"
    fi

    echo -e "${YELLOW}请重启 qBittorrent 服务以使修改生效${RESET}"
}

# 菜单
menu() {
    clear
    echo -e "${CYAN}==== qBittorrent-Nox 管理菜单 ====${RESET}"
    echo -e "1. 安装 & 部署 qBittorrent-Nox"
    echo -e "2. 启动 qBittorrent"
    echo -e "3. 停止 qBittorrent"
    echo -e "4. 重启 qBittorrent"
    echo -e "5. 查看日志"
    echo -e "6. 卸载 qBittorrent"
    echo -e "7. 重置 WebUI 密码"
    echo -e "8. 修改 WebUI 端口和用户名"
    echo -e "0. 退出"
    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read -r choice
    case "$choice" in
        1) install_qbittorrent ;;
        2) start_qbittorrent ;;
        3) stop_qbittorrent ;;
        4) restart_qbittorrent ;;
        5) logs_qbittorrent ;;
        6) uninstall_qbittorrent ;;
        7) reset_webui_password ;;
        8) modify_webui_settings ;;
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
