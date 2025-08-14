#!/bin/bash
# ========================================
# qBittorrent-Nox 一键管理脚本（支持设置非空密码）
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

# 安装 & 部署 qBittorrent-Nox
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
    sudo systemctl enable qbittorrent
    sudo systemctl start qbittorrent

    echo -e "${GREEN}qBittorrent-Nox 安装完成并已启动!${RESET}"
    echo -e "${CYAN}首次登录 WebUI 默认用户名: admin，密码请通过“修改 WebUI 设置”设置${RESET}"
}

# 启动
start_qbittorrent() {
    sudo systemctl start ${SERVICE_NAME}
    echo -e "${GREEN}qBittorrent 已启动${RESET}"
}

# 停止
stop_qbittorrent() {
    sudo systemctl stop ${SERVICE_NAME}
    echo -e "${YELLOW}qBittorrent 已停止${RESET}"
}

# 重启
restart_qbittorrent() {
    sudo systemctl restart ${SERVICE_NAME}
    echo -e "${GREEN}qBittorrent 已重启${RESET}"
}

# 查看日志
logs_qbittorrent() {
    sudo journalctl -u ${SERVICE_NAME} -f
}

# 卸载
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

# 设置 WebUI 用户名/密码/端口（密码非空）
modify_webui_settings() {
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        echo -e "${RED}配置目录不存在，请先启动一次 qBittorrent-Nox${RESET}"
        return
    fi

    mkdir -p "${CONFIG_DIR}"
    touch "${CONF_FILE}"

    echo -ne "${YELLOW}请输入 WebUI 用户名（回车保留 admin）: ${RESET}"
    read -r new_user
    new_user=${new_user:-admin}

    # 循环确保密码非空
    while true; do
        echo -ne "${YELLOW}请输入 WebUI 密码（不能为空）: ${RESET}"
        read -rs new_pass
        echo
        if [[ -n "$new_pass" ]]; then
            break
        else
            echo -e "${RED}密码不能为空，请重新输入${RESET}"
        fi
    done

    echo -ne "${YELLOW}请输入 WebUI 端口（回车保留 8080）: ${RESET}"
    read -r new_port
    new_port=${new_port:-8080}

    # 生成 HA1 = MD5("用户名:qBittorrent:密码")
    ha1=$(echo -n "${new_user}:qBittorrent:${new_pass}" | md5sum | awk '{print $1}')

    # 写入配置文件
    if ! grep -q "^\[Preferences\]" "${CONF_FILE}"; then
        echo "[Preferences]" > "${CONF_FILE}"
    fi

    # 替换或新增
    sed -i "/^WebUI\\Username=/d" "${CONF_FILE}"
    sed -i "/^WebUI\\Password_ha1=/d" "${CONF_FILE}"
    sed -i "/^WebUI\\Port=/d" "${CONF_FILE}"

    echo "WebUI\Username=${new_user}" >> "${CONF_FILE}"
    echo "WebUI\Password_ha1=@ByteArray(${ha1})" >> "${CONF_FILE}"
    echo "WebUI\Port=${new_port}" >> "${CONF_FILE}"

    echo -e "${GREEN}已成功修改 WebUI 设置！请重启服务生效${RESET}"
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
    echo -e "7. 设置 WebUI 用户名/密码/端口（密码非空）"
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
        7) modify_webui_settings ;;
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
