#!/bin/bash
# VPS 常用命令合集菜单
# 用法: bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-tools.sh)

while true; do
    clear
    echo "====== VPS 常用工具菜单 ======"
    echo "1. 卸载哪吒探针"
    echo "2. 更新哪吒探针 (apt)"
    echo "3. 更新系统"
    echo "4. 获取 root 权限"
    echo "5. 禁用哪吒 SSH 命令执行 (v1)"
    echo "6. 禁用哪吒 SSH 命令执行 (v0)"
    echo "7. DDNS 脚本"
    echo "8. 安装 Hysteria2"
    echo "0. 退出"
    echo "============================="
    read -rp "请输入选项编号: " choice

    case "$choice" in
        1)
            bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh)
            ;;
        2)
            apt install unzip -y
            ;;
        3)
            sudo apt update && sudo apt install curl -y
            ;;
        4)
            sudo -i
            ;;
        5)
            sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent
            ;;
        6)
            sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent
            ;;
        7)
            bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh)
            ;;
        8)
            wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh
            ;;
        0)
            echo "退出工具"
            exit 0
            ;;
        *)
            echo "无效选项，请重新输入"
            ;;
    esac

    echo ""
    read -rp "按回车键继续..."
done
