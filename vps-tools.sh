#!/bin/bash
# VPS Toolbox - 彩色二级菜单优化版（最终可运行）

INSTALL_PATH="$HOME/vps-toolbox.sh"
SHORTCUT_PATH="/usr/local/bin/m"
SHORTCUT_PATH_UPPER="/usr/local/bin/M"

# 颜色
green="\033[32m"
yellow="\033[33m"
red="\033[31m"
cyan="\033[36m"
magenta="\033[35m"
blue="\033[34m"
reset="\033[0m"

trap 'echo -e "\n${red}操作已中断${reset}"; exit 1' INT

rainbow_animate() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    for ((i=0;i<${#text};i++)); do
        printf "\033[%sm%s" "${colors[$((i % ${#colors[@]}))]}" "${text:$i:1}"
        sleep 0.002
    done
    printf "${reset}\n"
}

rainbow_border() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    local output=""
    local i=0
    for (( c=0;c<${#text};c++)); do
        output+="\033[${colors[$i]}m${text:$c:1}"
        ((i=(i+1)%${#colors[@]}))
    done
    echo -e "$output${reset}"
}

show_system_usage() {
    local width=40
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    disk_used_percent=$(df -h / | awk 'NR==2 {print $5}')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
    pad_string() { local str="$1"; printf "%-${width}s" "$str"; }
    echo -e "${yellow}┌$(printf '─%.0s' $(seq 1 $width))┐${reset}"
    echo -e "${yellow}│$(pad_string "📊 内存：${mem_used}Mi/${mem_total}Mi")│${reset}"
    echo -e "${yellow}│$(pad_string "💽 磁盘：${disk_used_percent} 用 / 总 ${disk_total}")│${reset}"
    echo -e "${yellow}│$(pad_string "⚙ CPU：${cpu_usage}%")│${reset}"
    echo -e "${yellow}└$(printf '─%.0s' $(seq 1 $width))┘${reset}\n"
}

print_option() {
    local num="$1"
    local text="$2"
    printf "${green}%02d  %-30s${reset}\n" "$num" "$text"
}

# ================= 数据化菜单 =================
MAIN_MENU=("系统设置" "面板相关" "代理" "应用商店" "Docker工具" "其他")
SUB_MENU[0]="更新源|安装curl|DDNS|本机信息|DDwindows10|临时禁用IPv6|添加SWAP|TCP窗口调优|安装Python|自定义DNS解锁|tun2socks|开放所有端口"
SUB_MENU[1]="宝塔面板|1panel面板|宝塔开心版|极光面板|哆啦A梦转发面板|国外机1Panel添加应用|国内机1Panel添加应用"
SUB_MENU[2]="Hysteria2|3XUI|WARP|Surge-Snell|国外机EZRealm|国内机EZRealm|3XUI-Alpines|gost"
SUB_MENU[3]="Sub-Store|WebSSH|Poste.io 邮局|OpenList|应用管理工具"
SUB_MENU[4]="安装 Docker Compose|Docker备份和恢复|Docker容器迁移|安装Docker"
SUB_MENU[5]="VPS管理|更新脚本|卸载工具箱"

# ================= 命令映射 =================
declare -A CMD_MAP
# 系统设置
CMD_MAP["更新源"]="sudo apt update"
CMD_MAP["安装curl"]="sudo apt install curl -y"
CMD_MAP["DDNS"]="bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh)"
CMD_MAP["本机信息"]="bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vpsinfo.sh)"
CMD_MAP["DDwindows10"]="bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang 'cn'"
CMD_MAP["临时禁用IPv6"]="sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1"
CMD_MAP["添加SWAP"]="wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh"
CMD_MAP["TCP窗口调优"]="wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh"
CMD_MAP["安装Python"]="curl -O https://raw.githubusercontent.com/lx969788249/lxspacepy/master/pyinstall.sh && chmod +x pyinstall.sh && ./pyinstall.sh"
CMD_MAP["自定义DNS解锁"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/media_dns.sh)"
CMD_MAP["tun2socks"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/tun2socks.sh)"
CMD_MAP["开放所有端口"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/open_all_ports.sh)"

# 面板相关
CMD_MAP["宝塔面板"]="if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi; bash install_panel.sh ed8484bec"
CMD_MAP["1panel面板"]="bash -c \"$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)\""
CMD_MAP["宝塔开心版"]="if [ -f /usr/bin/curl ]; then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh; else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh; fi; bash install_panel.sh www.BTKaiXin.com"
CMD_MAP["极光面板"]="bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)"
CMD_MAP["哆啦A梦转发面板"]="curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh"
CMD_MAP["国外机1Panel添加应用"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/update_local_apps.sh)"
CMD_MAP["国内机1Panel添加应用"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/ggupdate_local_apps.sh)"

# 代理
CMD_MAP["Hysteria2"]="wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh"
CMD_MAP["3XUI"]="bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)"
CMD_MAP["WARP"]="wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh"
CMD_MAP["Surge-Snell"]="bash <(curl -L -s menu.jinqians.com)"
CMD_MAP["国外机EZRealm"]="wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh"
CMD_MAP["国内机EZRealm"]="wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh"
CMD_MAP["3XUI-Alpines"]="apk add curl bash gzip openssl && bash <(curl -Ls https://raw.githubusercontent.com/StarVM-OpenSource/3x-ui-Apline/refs/heads/main/install.sh)"
CMD_MAP["gost"]="wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh"

# 应用商店
CMD_MAP["Sub-Store"]="docker run -it -d --restart=always -e 'SUB_STORE_CRON=0 0 * * *' -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store"
CMD_MAP["WebSSH"]="docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest"
CMD_MAP["Poste.io 邮局"]="curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh"
CMD_MAP["OpenList"]="curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh"
CMD_MAP["应用管理工具"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/vpsdocker.sh)"

# Docker工具
CMD_MAP["安装 Docker Compose"]="sudo apt install docker-compose-plugin -y"
CMD_MAP["Docker备份和恢复"]="curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh"
CMD_MAP["Docker容器迁移"]="curl -O https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh"
CMD_MAP["安装Docker"]="bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/Docker.sh)"

# 其他
CMD_MAP["VPS管理"]="curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-control.sh -o vps-control.sh && chmod +x vps-control.sh && ./vps-control.sh"
CMD_MAP["更新脚本"]="update_script"
CMD_MAP["卸载工具箱"]="uninstall_toolbox"

# ================= 菜单显示 =================
show_main_menu() {
    clear
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_animate "              📦 VPS 服务器工具箱 📦          "
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_system_usage
    echo -e "${cyan}【一级菜单】${reset}"
    for i in "${!MAIN_MENU[@]}"; do
        print_option $((i+1)) "${MAIN_MENU[$i]}"
    done
    print_option 0 "退出"
    rainbow_border "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

show_sub_menu() {
    local main_idx="$1"
    IFS='|' read -ra options <<< "${SUB_MENU[$((main_idx-1))]}"
    # 不同一级菜单使用不同颜色
    local color=$cyan
    case "$main_idx" in
        1) color=$yellow ;;
        2) color=$magenta ;;
        3) color=$blue ;;
        4) color=$green ;;
        5) color=$red ;;
        6) color=$cyan ;;
    esac
    echo -e "${color}【${MAIN_MENU[$((main_idx-1))]}】${reset}"
    declare -gA SUB_MAP
    for i in "${!options[@]}"; do
        print_option $((i+1)) "${options[$i]}"
        SUB_MAP[$((i+1))]="${options[$i]}"
    done
    print_option 0 "返回上级菜单"
}

execute_sub_choice() {
    local choice="$1"
    local cmd_name="${SUB_MAP[$choice]}"
    if [ "$cmd_name" == "update_script" ]; then
        echo -e "${green}正在从 GitHub 拉取最新版本...${reset}"
        tmp_file=$(mktemp)
        curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-tools.sh -o "$tmp_file" \
        && chmod +x "$tmp_file" \
        && mv "$tmp_file" "$(realpath "$0")" \
        && echo -e "${green}更新完成，重新启动脚本...${reset}" \
        && exec "$(realpath "$0")"
        echo -e "${red}更新失败，请检查网络或仓库地址${reset}"
    elif [ "$cmd_name" == "uninstall_toolbox" ]; then
        echo -e "${red}卸载工具箱...${reset}"
        rm -f "$INSTALL_PATH" "$(realpath "$0")"
        remove_shortcut
        echo -e "${green}卸载完成${reset}"
        exit 0
    else
        eval "${CMD_MAP[$cmd_name]}"
    fi
}

install_shortcut() {
    echo -e "${green}创建快捷指令 m 和 M${reset}"
    local script_path
    script_path=$(realpath "$0")
    sudo ln -sf "$script_path" "$SHORTCUT_PATH"
    sudo ln -sf "$script_path" "$SHORTCUT_PATH_UPPER"
    sudo chmod +x "$script_path"
    echo -e "${green}安装完成！输入 m 或 M 运行工具箱${reset}"
}

remove_shortcut() {
    sudo rm -f "$SHORTCUT_PATH" "$SHORTCUT_PATH_UPPER"
    echo -e "${red}已删除快捷指令 m 和 M${reset}"
}

if [ ! -f "$SHORTCUT_PATH" ] || [ ! -f "$SHORTCUT_PATH_UPPER" ]; then
    install_shortcut
fi

# ================= 主循环 =================
while true; do
    show_main_menu
    read -rp "请选择一级菜单编号: " main_choice
    if [ "$main_choice" -eq 0 ]; then
        echo -e "${yellow}退出${reset}"
        exit 0
    fi
    while true; do
        show_sub_menu "$main_choice"
        read -rp "请选择二级菜单编号: " sub_choice
        if [ "$sub_choice" -eq 0 ]; then
            break
        fi
        execute_sub_choice "$sub_choice"
        read -rp "按回车返回二级菜单..."
    done
done
