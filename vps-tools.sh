#!/bin/bash
# VPS Toolbox - 交互式二级菜单版
# 功能：
# - 一级菜单加 ▶ 标识，字体绿色
# - 二级菜单简洁显示
# - 更新/卸载单独一级菜单
# - 快捷指令 m / M 自动创建
# - 系统信息面板保留
# - 彩色菜单和动态彩虹标题

INSTALL_PATH="$HOME/vps-toolbox.sh"
SHORTCUT_PATH="/usr/local/bin/m"
SHORTCUT_PATH_UPPER="/usr/local/bin/M"

# 颜色
green="\033[32m"
reset="\033[0m"
yellow="\033[33m"
red="\033[31m"
cyan="\033[36m"

# Ctrl+C 中断保护
trap 'echo -e "\n${red}操作已中断${reset}"; exit 1' INT

# 丝滑动态彩虹标题
rainbow_animate() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    local len=${#text}
    for ((i=0; i<len; i++)); do
        printf "\033[%sm%s" "${colors[$((i % ${#colors[@]}))]}" "${text:$i:1}"
        sleep 0.002
    done
    printf "${reset}\n"
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

# 一级菜单列表
MAIN_MENU=(
    "系统设置"
    "哪吒相关"
    "面板相关"
    "代理"
    "网络解锁"
    "应用商店"
    "VPS设置"
    "Docker工具"
    "证书工具"
    "更新/卸载"
)

# 二级菜单列表
SUB_MENU[1]="01 更新源|02 安装curl|03 DDNS|04 本机信息|05 DDwindows10|06 临时禁用IPv6|07 添加SWAP|08 TCP窗口调优|09 安装Python|10 自定义DNS解锁|11 tun2socks|12 开放所有端口"
SUB_MENU[2]="13 安装unzip|14 卸载哪吒探针|15 v1关SSH|16 v0关SSH|17 V0哪吒监控"
SUB_MENU[3]="18 宝塔面板|19 1panel面板|20 宝塔开心版|21 极光面板|22 哆啦A梦转发面板|23 国外机1Panel添加应用|24 国内机1Panel添加应用"
SUB_MENU[4]="25 Hysteria2|26 3XUI|27 WARP|28 Surge-Snell|29 国外机EZRealm|30 国内机EZRealm|31 3XUI-Alpines|32 gost"
SUB_MENU[5]="33 IP解锁-IPv4|34 IP解锁-IPv6|35 网络质量-IPv4|36 网络质量-IPv6|37 NodeQuality脚本|38 流媒体解锁|39 融合怪测试|40 国外机三网测速|41 国内机三网测速|42 国外机三网延迟测试|43 国内机三网延迟测试"
SUB_MENU[6]="44 Sub-Store|45 WebSSH|46 Poste.io 邮局|47 OpenList|48 应用管理工具"
SUB_MENU[7]="49 老王工具箱|50 科技lion|51 一点科技|52 服务器优化工具|53 VPS-Toolkit|54 VPS管理"
SUB_MENU[8]="55 安装 DockerCompose|56 Docker备份和恢复|57 Docker容器迁移|58 Docker管理"
SUB_MENU[9]="59 NGINX反代|60 1kejiNGINX反代(V4)|61 1kejiNGINX反代(V6)"
SUB_MENU[10]="89 更新脚本|99 卸载工具箱|0 退出"

# 显示一级菜单
show_main_menu() {
    clear
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_animate "              📦 VPS 服务器工具箱 📦          "
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_system_usage
    for i in "${!MAIN_MENU[@]}"; do
        echo -e "${green}▶ $((i+1)). ${MAIN_MENU[i]}${reset}"
    done
    echo
}

# 显示二级菜单并选择
show_sub_menu() {
    local idx="$1"
    IFS='|' read -ra options <<< "${SUB_MENU[idx]}"
    for opt in "${options[@]}"; do
        echo -e "${green}$opt${reset}"
    done
    read -rp "请输入要执行的编号 (b返回一级菜单): " choice
    if [[ "$choice" == "b" ]]; then
        return
    fi
    execute_choice "$choice"
    read -rp "按回车返回二级菜单..." tmp
}

# 安装快捷指令
install_shortcut() {
    echo -e "${green}创建快捷指令 m 和 M${reset}"
    local script_path
    script_path=$(readlink -f "$0")
    sudo chmod +x "$script_path"
    sudo ln -sf "$script_path" "$SHORTCUT_PATH"
    sudo ln -sf "$script_path" "$SHORTCUT_PATH_UPPER"
    echo -e "${green}安装完成！输入 m 或 M 运行工具箱${reset}"
}

# 删除快捷指令
remove_shortcut() {
    sudo rm -f "$SHORTCUT_PATH" "$SHORTCUT_PATH_UPPER"
}

# 执行菜单选项（完整补全）
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
        11) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/tun2socks.sh) ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/open_all_ports.sh) ;;
        13) sudo apt install unzip -y ;;
        14) bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh) ;;
        15) sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent ;;
        16) sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent ;;
        17) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh) ;;
        18) if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi; bash install_panel.sh ed8484bec ;;
        19) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)" ;;
        20) if [ -f /usr/bin/curl ]; then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh; else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh; fi; bash install_panel.sh www.BTKaiXin.com ;;
        21) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        22) curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        23) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/update_local_apps.sh) ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/ggupdate_local_apps.sh) ;;
        25) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh ;;
        26) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
        27) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        28) bash <(curl -L -s menu.jinqians.com) ;;
        29) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        30) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        31) apk add curl bash gzip openssl && bash <(curl -Ls https://raw.githubusercontent.com/StarVM-OpenSource/3x-ui-Apline/refs/heads/main/install.sh) ;;
        32) wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh ;;
        33) bash <(curl -Ls https://IP.Check.Place) -4 ;;
        34) bash <(curl -Ls https://IP.Check.Place) -6 ;;
        35) bash <(curl -Ls https://Net.Check.Place) -4 ;;
        36) bash <(curl -Ls https://Net.Check.Place) -6 ;;
        37) bash <(curl -sL https://run.NodeQuality.com) ;;
        38) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        39) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        40) bash <(wget -qO- bash.spiritlhl.net/ecs-cn) ;;
        41) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-cn.sh) ;;
        42) bash <(wget -qO- bash.spiritlhl.net/ecs-ping) ;;
        43) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh) ;;
        44) docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store ;;
        45) docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest ;;
        46) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        47) curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh ;;
        48) curl -fsSL https://raw.githubusercontent.com/iu683/app-store/main/vpsdocker.sh -o vpsdocker.sh && chmod +x vpsdocker.sh && ./vpsdocker.sh ;;
        49) curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh ;;
        50) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh ;;
        51) curl -sSL https://yidian.icu/ty.sh -o ty.sh && chmod +x ty.sh && ./ty.sh ;;
        52) curl -sSL https://raw.githubusercontent.com/iu683/vps-tools/main/optimize.sh -o optimize.sh && chmod +x optimize.sh && ./optimize.sh ;;
        53) curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-toolkit.sh -o vps-toolkit.sh && chmod +x vps-toolkit.sh && ./vps-toolkit.sh ;;
        54) curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-control.sh -o vps-control.sh && chmod +x vps-control.sh && ./vps-control.sh ;;
        55) curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose ;;
        56) bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/docker-backup.sh) ;;
        57) bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/docker-migrate.sh) ;;
        58) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/Docker.sh) ;;
        59) bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/manage_nginx.sh) ;;
        60) bash <(curl -fsSL https://raw.githubusercontent.com/1keji/AddIPv6/main/manage_nginx.sh) ;;
        61) bash <(curl -fsSL https://raw.githubusercontent.com/1keji/AddIPv6/main/manage_nginx_v6.sh) ;;
        89) bash "$INSTALL_PATH" update ;;
        99) 
            echo -e "${yellow}正在卸载工具箱...${reset}"
            remove_shortcut
            rm -f "$INSTALL_PATH"
            echo -e "${green}卸载完成！${reset}"
            exit 0
            ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项${reset}" ;;
    esac
}

# 自动创建快捷指令
install_shortcut

# 主循环
while true; do
    show_main_menu
    read -rp "请选择一级菜单编号 (0退出): " main_choice
    if [[ "$main_choice" == "0" ]]; then
        echo -e "${yellow}退出${reset}"
        exit 0
    fi
    if [[ "$main_choice" -ge 1 && "$main_choice" -le "${#MAIN_MENU[@]}" ]]; then
        show_sub_menu "$main_choice"
    else
        echo -e "${red}无效选项${reset}"
        sleep 1
    fi
done
