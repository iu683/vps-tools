#!/bin/bash

# 彩虹颜色数组
COLORS=(
    "\033[38;5;196m" # 红
    "\033[38;5;202m" # 橙
    "\033[38;5;226m" # 黄
    "\033[38;5;46m"  # 绿
    "\033[38;5;21m"  # 蓝
    "\033[38;5;93m"  # 靛
    "\033[38;5;201m" # 紫
)
RESET="\033[0m"

# 功能列表（按原顺序）
menu_items=(
    "更新源|sudo apt update"
    "更新curl|sudo apt install curl"
    "哪吒压缩包|apt install unzip -y"
    "哪吒卸载|bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh)"
    "v1关SSH|sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent"
    "v0关SSH|sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent"
    "DDNS|bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh)"
    "HY2|wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh"
    "3XUI|bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)"
    "老王工具箱|curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh"
    "科技lion|curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh"
    "WARP|wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh"
    "SNELL|bash <(curl -L -s menu.jinqians.com)"
    "EZRealm国外|wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh"
    "EZRealm国内|wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh"
    "V0哪吒|bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh)"
    "一点科技|wget -O 1keji.sh \"https://www.1keji.net\" && chmod +x 1keji.sh && ./1keji.sh"
    "Sub-Store|docker run -it -d --restart=always -e \"SUB_STORE_CRON=0 0 * * *\" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store"
    "宝塔面板|if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec"
    "1Panel|bash -c \"\$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)\""
    "WEBSSH|docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest"
    "宝塔开心版|if [ -f /usr/bin/curl ];then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh;else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh;fi;bash install_panel.sh www.BTKaiXin.com"
    "IP解锁-IPv4|bash <(curl -Ls https://IP.Check.Place) -4"
    "IP解锁-IPv6|bash <(curl -Ls https://IP.Check.Place) -6"
    "网络质量-IPv4|bash <(curl -Ls https://Net.Check.Place) -4"
    "网络质量-IPv6|bash <(curl -Ls https://Net.Check.Place) -6"
    "NodeQuality|bash <(curl -sL https://run.NodeQuality.com)"
    "卸载工具箱|rm -f \"$0\" && echo '工具箱已卸载'"
)

# 显示彩虹渐变标题
draw_rainbow_line() {
    local len=$1
    local out=""
    for ((i=0;i<len;i++)); do
        color="${COLORS[i % ${#COLORS[@]}]}"
        out+="${color}━${RESET}"
    done
    echo -e "$out"
}

# 打印菜单
show_menu() {
    clear
    draw_rainbow_line 70
    echo -e "       \033[1;97m🌈 终端彩虹工具箱 🌈\033[0m"
    draw_rainbow_line 70

    local cols=4
    local count=${#menu_items[@]}
    local rows=$(( (count + cols - 1) / cols ))
    local index=1

    for ((r=0; r<rows; r++)); do
        line=""
        for ((c=0; c<cols; c++)); do
            idx=$((r + c * rows))
            if [ $idx -lt $count ]; then
                title="${menu_items[$idx]%%|*}"
                line+=$(printf "\033[1;36m%2d\033[0m. %-17s" "$index" "$title")
                ((index++))
            fi
        done
        echo -e "$line"
    done

    draw_rainbow_line 70
}

# 执行选项
run_option() {
    local choice=$1
    if [[ "$choice" =~ ^[0-9]+$ && $choice -ge 1 && $choice -le ${#menu_items[@]} ]]; then
        cmd="${menu_items[$((choice-1))]#*|}"
        eval "$cmd"
    else
        echo -e "\033[31m无效选项\033[0m"
    fi
}

# 快捷键绑定
bind '"\em":"clear && bash '$0'\n"'

# 主循环
while true; do
    show_menu
    read -rp "请输入序号 (或 m/M 重新打开): " choice
    if [[ "$choice" =~ ^[mM]$ ]]; then
        continue
    fi
    run_option "$choice"
    read -rp "按回车返回菜单..." _
done
