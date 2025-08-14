#!/bin/bash

green="\033[32m"
red="\033[31m"
reset="\033[0m"

while true; do
    echo -e "${green}=== VPS 管理菜单 ===${reset}"
    echo -e "${green}1.${reset} 重启 VPS"
    echo -e "${green}2.${reset} 关机 VPS"
    echo -e "${green}3.${reset} 修改 root 密码"
    echo -e "${green}0.${reset} 退出"
    echo
    read -p "请输入数字选择操作: " choice

    case "$choice" in
        1)
            echo -e "${red}正在重启 VPS...${reset}"
            sudo reboot
            ;;
        2)
            echo -e "${red}正在关机 VPS...${reset}"
            sudo poweroff
            ;;
        3)
            echo -e "${green}请输入新的 root 密码:${reset}"
            sudo passwd root
            ;;
        0)
            echo -e "${green}已退出${reset}"
            break
            ;;
        *)
            echo -e "${red}无效选择！请重新输入${reset}"
            ;;
    esac

    echo   # 添加空行，界面更整洁
done
