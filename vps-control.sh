#!/bin/bash

green="\033[32m"
red="\033[31m"
reset="\033[0m"

echo -e "${green}=== VPS 管理菜单 ===${reset}"
echo -e "${green}1.${reset} 重启 VPS"
echo -e "${green}2.${reset} 关机 VPS"
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
    0)
        echo -e "${green}已退出${reset}"
        ;;
    *)
        echo -e "${red}无效选择！${reset}"
        ;;
esac
