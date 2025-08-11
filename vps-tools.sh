#!/bin/bash

# 彩虹边框绘制
draw_border() {
    local colors=("\033[1;31m" "\033[1;33m" "\033[1;32m" "\033[1;36m" "\033[1;34m" "\033[1;35m")
    local reset="\033[0m"
    local width=55
    for ((i=0; i<$width; i++)); do
        echo -ne "${colors[i % ${#colors[@]}]}━${reset}"
    done
    echo
}

# 彩虹标题
draw_title() {
    local text=$1
    local colors=("\033[1;31m" "\033[1;33m" "\033[1;32m" "\033[1;36m" "\033[1;34m" "\033[1;35m")
    local reset="\033[0m"
    echo -ne "┃"
    for ((i=0; i<${#text}; i++)); do
        local c=${text:$i:1}
        echo -ne "${colors[i % ${#colors[@]}]}$c${reset}"
    done
    echo -e "┃"
}

# 菜单
show_menu() {
    clear
    draw_border
    draw_title "   🖥️ 服务器工具箱 🖥️   "
    draw_border
    echo -e "  1. 更新源               2. 更新curl"
    echo -e "  3. 哪吒压缩包           4. 卸载哪吒探针"
    echo -e "  5. v1关SSH              6. v0关SSH"
    echo -e "  7. DDNS                 8. HY2"
    echo -e "  9. 3XUI                 10. 老王工具箱"
    echo -e " 11. 科技lion             12. WARP"
    echo -e " 13. SNELL                14. 国外EZRealm"
    echo -e " 15. 国内EZRealm          16. v0哪吒"
    echo -e " 17. 一点科技             18. Sub-Store"
    echo -e " 19. 宝塔面板             20. 1panel面板"
    echo -e " 21. WEBSSH               22. 宝塔开心版"
    echo -e " 23. IP解锁-IPv4          24. IP解锁-IPv6"
    echo -e " 25. 网络质量-IPv4        26. 网络质量-IPv6"
    echo -e " 27. NodeQuality脚本      99. 卸载工具箱"
    echo -e "                          0. 退出"
    draw_border
}

# 执行命令
run_cmd() {
    case $1 in
        1) sudo apt update ;;
        2) sudo apt install curl ;;
        3) apt install unzip -y ;;
        4) bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh) ;;
        5) sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent ;;
        6) sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent ;;
        7) bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh) ;;
        8) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh ;;
        9) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
        10) curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh ;;
        11) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh ;;
        12) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        13) bash <(curl -L -s menu.jinqians.com) ;;
        14) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        15) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        16) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh) ;;
        17) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh ;;
        18) docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store ;;
        19) if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec ;;
        20) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)" ;;
        21) docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest ;;
        22) if [ -f /usr/bin/curl ];then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh;else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh;fi;bash install_panel.sh www.BTKaiXin.com ;;
        23) bash <(curl -Ls https://IP.Check.Place) -4 ;;
        24) bash <(curl -Ls https://IP.Check.Place) -6 ;;
        25) bash <(curl -Ls https://Net.Check.Place) -4 ;;
        26) bash <(curl -Ls https://Net.Check.Place) -6 ;;
        27) bash <(curl -sL https://run.NodeQuality.com) ;;
        99) echo "卸载工具箱功能未实现，可手动删除脚本。" ;;
        0) exit 0 ;;
        *) echo "无效选项" ;;
    esac
}

# 主循环
while true; do
    show_menu
    read -p "请输入选项: " choice
    run_cmd $choice
    echo -e "\n按回车键返回菜单..."
    read
done
