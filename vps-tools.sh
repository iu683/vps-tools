#!/bin/bash
# VPS Toolbox - 最终整合美化版（原样执行逻辑 + 丝滑彩虹标题 + 对齐菜单 + 更新脚本功能）
# - 所有执行逻辑保持原命令不变
# - 美化：丝滑动态彩虹标题、系统信息面板、彩色分类菜单、编号补零
# - 退出项 0 不补零，其余两位补零
# - 新增 89 更新脚本功能
# - 首次运行自动安装快捷方式 m / M

INSTALL_PATH="$HOME/vps-toolbox.sh"
SHORTCUT_PATH="/usr/local/bin/m"
SHORTCUT_PATH_UPPER="/usr/local/bin/M"

# 颜色
green="\033[32m"
reset="\033[0m"
yellow="\033[33m"
red="\033[31m"

# Ctrl+C 中断保护
trap 'echo -e "\n${red}操作已中断${reset}"; exit 1' INT

# 丝滑动态彩虹标题
rainbow_animate() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    local len=${#text}
    for ((i=0; i<len; i++)); do
        printf "\033[%sm%s" "${colors[$((i % ${#colors[@]}))]}" "${text:$i:1}"
        sleep 0.005
    done
    printf "${reset}\n"
}

# 彩虹静态边框
rainbow_border() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    local output=""
    local i=0
    for (( c=0; c<${#text}; c++ )); do
        output+="\033[${colors[$i]}m${text:$c:1}"
        ((i=(i+1)%${#colors[@]}))
    done
    echo -e "$output${reset}"
}

# 系统资源显示
show_system_usage() {
    local width=36
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    disk_used_percent=$(df -h / | awk 'NR==2 {print $5}')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
    pad_string() { local str="$1"; printf "%${width}s" "$str"; }
    echo -e "${yellow}┌$(printf '─%.0s' $(seq 1 $width))┐${reset}"
    echo -e "${yellow}$(pad_string "📊 内存：${mem_used}Mi/${mem_total}Mi")${reset}"
    echo -e "${yellow}$(pad_string "💽 磁盘：${disk_used_percent} 用 / 总 ${disk_total}")${reset}"
    echo -e "${yellow}$(pad_string "⚙ CPU：${cpu_usage}%")${reset}"
    echo -e "${yellow}└$(printf '─%.0s' $(seq 1 $width))┘${reset}\n"
}

# 打印菜单项
print_option() {
    local num="$1"
    local text="$2"
    if [ "$num" -eq 0 ]; then
        printf "${green}%-3s %-30s${reset}\n" "$num" "$text"
    else
        printf "${green}%02d  %-30s${reset}\n" "$num" "$text"
    fi
}

# 显示菜单
show_menu() {
    clear
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_animate "              📦 VPS 服务器工具箱 📦          "
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_system_usage

    echo -e "${red}【系统设置】${reset}"
    print_option 1  "更新源"
    print_option 2  "安装curl"
    print_option 3  "DDNS"
    print_option 4  "本机信息"
    print_option 5  "DDwindows10"
    print_option 6  "临时禁用IPv6"
    print_option 7  "添加SWAP"
    print_option 8  "TCP窗口调优"
    print_option 9  "安装Python"
    print_option 10 "自定义DNS解锁"

    echo -e "\n${red}【哪吒相关】${reset}"
    print_option 11 "安装解压工具"
    print_option 12 "卸载哪吒探针"
    print_option 13 "v1关SSH"
    print_option 14 "v0关SSH"
    print_option 15 "V0哪吒监控"

    echo -e "\n${red}【面板相关】${reset}"
    print_option 16 "宝塔面板"
    print_option 17 "1panel面板"
    print_option 18 "宝塔开心版"
    print_option 19 "极光面板"
    print_option 20 "哆啦A梦转发面板"

    echo -e "\n${red}【代理】${reset}"
    print_option 21 "Hysteria2"
    print_option 22 "3XUI"
    print_option 23 "WARP"
    print_option 24 "Surge-Snell"
    print_option 25 "国外机EZRealm"
    print_option 26 "国内机EZRealm"
    print_option 27 "3XUI-Alpines"
    print_option 28 "gost"

    echo -e "\n${red}【网络解锁】${reset}"
    print_option 29 "IP解锁-IPv4"
    print_option 30 "IP解锁-IPv6"
    print_option 31 "网络质量-IPv4"
    print_option 32 "网络质量-IPv6"
    print_option 33 "NodeQuality脚本"
    print_option 34 "流媒体解锁"
    print_option 35 "融合怪测试"
    print_option 36 "国外机三网测速"
    print_option 37 "国内机三网测速"
    print_option 38 "国外机三网延迟测试"
    print_option 39 "国内机三网延迟测试"

    echo -e "\n${red}【应用商店】${reset}"
    print_option 40 "Sub-Store"
    print_option 41 "WebSSH"
    print_option 42 "Poste.io 邮局"
    print_option 43 "OpenList"

    echo -e "\n${red}【工具箱】${reset}"
    print_option 44 "老王工具箱"
    print_option 45 "科技lion"
    print_option 46 "一点科技"
    print_option 47 "服务器优化工具"
    print_option 48 "VPS-Toolkit"

    echo -e "\n${red}【Docker工具】${reset}"
    print_option 49 "安装 Docker Compose"
    print_option 50 "Docker备份和恢复"
    print_option 51 "Docker容器迁移"

    echo -e "\n${red}【证书工具】${reset}"
    print_option 52 "NGINX反代"

    echo -e "\n${red}【其他】${reset}"
    print_option 88 "VPS管理"
    print_option 89 "更新脚本"
    print_option 99 "卸载工具箱"
    print_option 0  "退出"

    rainbow_border "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 安装快捷指令
install_shortcut() {
    echo -e "${green}创建快捷指令 m 和 M${reset}"
    local script_path
    script_path=$(realpath "$0")
    sudo ln -sf "$script_path" "$SHORTCUT_PATH"
    sudo ln -sf "$script_path" "$SHORTCUT_PATH_UPPER"
    sudo chmod +x "$script_path"
    echo -e "${green}安装完成！输入 m 或 M 运行工具箱${reset}"
}

# 删除快捷指令
remove_shortcut() {
    sudo rm -f "$SHORTCUT_PATH" "$SHORTCUT_PATH_UPPER"
    echo -e "${red}已删除快捷指令 m 和 M${reset}"
}

# 执行菜单选项
execute_choice() {
    case "$1" in
        1) sudo apt update ;;
        2) sudo apt install curl -y ;;
        3) bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh) ;;
        4) bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vpsinfo.sh) ;;
        5) bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang "cn" ;;
        6) sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 ;;
        7) wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh ;;
        8) wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh ;;
        9) curl -O https://raw.githubusercontent.com/lx969788249/lxspacepy/master/pyinstall.sh && chmod +x pyinstall.sh && ./pyinstall.sh ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/media_dns.sh) ;;
        11) sudo apt install unzip -y ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh) ;;
        13) sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent ;;
        14) sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent ;;
        15) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh) ;;
        16) if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi; bash install_panel.sh ed8484bec ;;
        17) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)" ;;
        18) if [ -f /usr/bin/curl ]; then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh; else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh; fi; bash install_panel.sh www.BTKaiXin.com ;;
        19) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        20) curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        21) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh ;;
        22) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
        23) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        24) bash <(curl -L -s menu.jinqians.com) ;;
        25) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        26) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        27) apk add curl bash gzip openssl && bash <(curl -Ls https://raw.githubusercontent.com/StarVM-OpenSource/3x-ui-Apline/refs/heads/main/install.sh) ;;
        28) wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh ;;
        29) bash <(curl -Ls https://IP.Check.Place) -4 ;;
        30) bash <(curl -Ls https://IP.Check.Place) -6 ;;
        31) bash <(curl -Ls https://Net.Check.Place) -4 ;;
        32) bash <(curl -Ls https://Net.Check.Place) -6 ;;
        33) bash <(curl -sL https://run.NodeQuality.com) ;;
        34) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        35) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        36) bash <(wget -qO- bash.spiritlhl.net/ecs-cn) ;;
        37) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-cn.sh) ;;
        38) bash <(wget -qO- bash.spiritlhl.net/ecs-ping) ;;
        39) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh) ;;
        40) docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store ;;
        41) docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest ;;
        42) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        43) curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh ;;
        44) curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh ;;
        45) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh ;;
        46) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh ;;
        47) bash <(curl -sL ss.hide.ss) ;;
        48) bash <(curl -sSL https://raw.githubusercontent.com/zeyu8023/vps_toolkit/main/install.sh) ;;
        49) sudo apt install docker-compose-plugin -y ;;
        50) curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh ;;
        51) curl -O https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh ;;
        52) bash <(curl -sL kejilion.sh) fd ;;
        88) curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-control.sh -o vps-control.sh && chmod +x vps-control.sh && ./vps-control.sh ;;
        89) 
            echo -e "${green}正在从 GitHub 拉取最新版本...${reset}"
            tmp_file=$(mktemp)
            curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-tools.sh -o "$tmp_file" \
            && chmod +x "$tmp_file" \
            && mv "$tmp_file" "$(realpath "$0")" \
            && echo -e "${green}更新完成，重新启动脚本...${reset}" \
            && exec "$(realpath "$0")"
            echo -e "${red}更新失败，请检查网络或仓库地址${reset}"
        ;;
        99) echo -e "${red}卸载工具箱...${reset}"; rm -f "$INSTALL_PATH" "$(realpath "$0")"; remove_shortcut; echo -e "${green}卸载完成${reset}"; exit 0 ;;
        0) echo -e "${yellow}退出${reset}"; exit 0 ;;
        *) echo -e "${red}无效选项${reset}" ;;
    esac
}

# 首次运行安装快捷方式
if [ ! -f "$SHORTCUT_PATH" ] || [ ! -f "$SHORTCUT_PATH_UPPER" ]; then
    install_shortcut
fi

# 主循环
while true; do
    show_menu
    read -p "请输入选项编号: " choice
    execute_choice "$choice"
    echo
    read -p "按回车返回菜单..."
done
