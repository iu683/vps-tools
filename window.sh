#!/bin/bash
# ========================================
# Windows 10 DD 重装菜单脚本（增强版 + 重启提示 + Root 检测 + 绝对路径修正）
# 作者: 整理示例
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 检测是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 用户或 sudo 运行此脚本${RESET}"
    echo -e "${YELLOW}示例: sudo bash $0${RESET}"
    exit 1
fi

# 更新系统和安装工具
install_tools() {
    echo -e "${GREEN}正在更新系统并安装必要工具...${RESET}"
    apt update && apt install curl wget -y
}

# 显示默认账户信息
show_account_info() {
    echo -e "${YELLOW}默认账户信息:${RESET}"
    echo -e "${YELLOW}用户名: Administrator${RESET}"
    echo -e "${YELLOW}密码: Teddysun.com${RESET}"
}

# 提示重启
prompt_reboot() {
    echo -ne "${YELLOW}是否立即重启系统？(y/n): ${RESET}"
    read answer
    case $answer in
        [Yy]*) 
            echo -e "${GREEN}系统即将重启...${RESET}"
            reboot
            ;;
        *) 
            echo -e "${GREEN}请在合适的时候手动重启系统${RESET}"
            ;;
    esac
}

# 下载文件函数，带进度和错误检测
download_file() {
    local url="$1"
    local output="$2"

    echo -e "${GREEN}正在下载: $url${RESET}"
    if command -v curl >/dev/null 2>&1; then
        curl -# -O "$url"
        status=$?
    else
        wget --progress=bar:force "$url" -O "$output"
        status=$?
    fi

    if [ $status -ne 0 ]; then
        echo -e "${RED}下载失败，请检查网络或链接${RESET}"
        exit 1
    fi
}

# V4DD 安装流程
install_v4dd() {
    echo -e "${GREEN}开始 V4DD Windows 10 安装流程...${RESET}"
    bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang "cn"
    show_account_info
    prompt_reboot
}

# V6DD 安装流程（绝对路径 + 错误检测）
install_v6dd() {
    echo -e "${GREEN}开始 V6DD Windows 10 安装流程...${RESET}"
    
    # 下载脚本
    download_file "https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh" "reinstall.sh"
    chmod +x reinstall.sh
    
    # 下载镜像
    download_file "https://dl.lamp.sh/vhd/zh-cn_windows10_ltsc.xz" "zh-cn_windows10_ltsc.xz"
    
    # 使用绝对路径
    IMG_PATH="$(pwd)/zh-cn_windows10_ltsc.xz"
    if [ ! -f "$IMG_PATH" ]; then
        echo -e "${RED}镜像文件不可访问，请检查下载或路径${RESET}"
        exit 1
    fi

    # 执行安装
    bash reinstall.sh dd --img "$IMG_PATH"

    show_account_info
    prompt_reboot
}

# 菜单
while true; do
    clear
    echo -e "${GREEN}===================================${RESET}"
    echo -e "${GREEN}       Windows 10 DD 安装脚本       ${RESET}"
    echo -e "${GREEN}===================================${RESET}"
    echo -e "${YELLOW}1) 安装必要工具${RESET}"
    echo -e "${YELLOW}2) V4DD 安装 Windows 10${RESET}"
    echo -e "${YELLOW}3) V6DD 安装 Windows 10${RESET}"
    echo -e "${YELLOW}0) 退出${RESET}"
    echo -ne "请输入编号: "
    read choice
    case $choice in
        1) install_tools ;;
        2) install_v4dd ;;
        3) install_v6dd ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入${RESET}" ;;
    esac
    echo -e "\n按回车返回菜单..."
    read
done
