#!/bin/bash
# VPS Toolbox - 最终整合版
# 功能：
# - 一级菜单加 ▶ 标识，字体绿色
# - 二级菜单简洁显示，输入 1~99 都可执行
# - 快捷指令 m / M 自动创建
# - 系统信息面板保留
# - 彩色菜单和动态彩虹标题
# - 完整安装/卸载逻辑

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

# 彩虹标题
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

# 一级菜单
MAIN_MENU=(
    "系统设置"
    "哪吒相关"
    "面板相关"
    "代理"
    "网络解锁"
    "应用商店"
    "VPS工具箱合集"
    "Docker工具"
    "证书工具"
    "更新/卸载"
)

# 二级菜单（编号去掉前导零，显示时格式化为两位数）
SUB_MENU[1]="1 更新源|2 安装curl|3 DDNS|4 本机信息|5 DDwindows10|6 临时禁用IPv6|7 添加SWAP|8 TCP窗口调优|9 安装Python|10 自定义DNS解锁|11 tun2socks|12 开放所有端口|13 VPS管理"
SUB_MENU[2]="14 安装unzip|15 卸载哪吒探针|16 v1关SSH|17 v0关SSH|18 V0哪吒监控"
SUB_MENU[3]="19 宝塔面板|20 1panel面板|21 宝塔开心版|22 极光面板|23 哆啦A梦转发面板|24 国外机1Panel添加应用|25 国内机1Panel添加应用"
SUB_MENU[4]="26 Hysteria2|27 3XUI|28 WARP|29 Surge-Snell|30 国外机EZRealm|31 国内机EZRealm|32 3XUI-Alpines|33 gost"
SUB_MENU[5]="34 IP解锁-IPv4|35 IP解锁-IPv6|36 网络质量-IPv4|37 网络质量-IPv6|38 NodeQuality脚本|39 流媒体解锁|40 融合怪测试|41 国外机三网测速|42 国内机三网测速|43 国外机三网延迟测试|44 国内机三网延迟测试"
SUB_MENU[6]="45 Sub-Store|46 WebSSH|47 Poste.io 邮局|48 OpenList|49 应用管理工具"
SUB_MENU[7]="50 老王工具箱|51 科技lion|52 一点科技|53 服务器优化工具|54 VPS-Toolkit"
SUB_MENU[8]="55 安装 DockerCompose|56 Docker备份和恢复|57 Docker容器迁移|58 Docker管理"
SUB_MENU[9]="59 NGINX反代|60 1kejiNGINX反代(V4)|61 1kejiNGINX反代(V6)"
SUB_MENU[10]="88 更新脚本|99 卸载工具箱"

# 显示一级菜单
show_main_menu() {
    clear
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_animate "              📦 VPS 服务器工具箱 📦          "
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_system_usage
    for i in "${!MAIN_MENU[@]}"; do
        printf "${green}▶ %02d. %s${reset}\n" "$((i+1))" "${MAIN_MENU[i]}"
    done
    echo
}

# 显示二级菜单并选择
show_sub_menu() {
    local idx="$1"
    while true; do
        IFS='|' read -ra options <<< "${SUB_MENU[idx]}"
        local map=()
        echo
        for opt in "${options[@]}"; do
            local num="${opt%% *}"
            local name="${opt#* }"
            printf "${green}%02d %s${reset}\n" "$num" "$name"
            map+=("$num")
        done

        echo -ne "${red}请输入要执行的编号 ${yellow}(00返回一级菜单)${red}：${reset}"
        read -r choice

        # 按回车直接刷新菜单
        if [[ -z "$choice" ]]; then
            clear
            continue
        fi

        # 输入 00 返回一级菜单
        if [[ "$choice" == "00" ]]; then
            return
        fi

        # 判断是否为有效选项
        if [[ ! " ${map[*]} " =~ (^|[[:space:]])$choice($|[[:space:]]) ]]; then
            echo -e "${red}无效选项${reset}"
            continue
        fi

        # 执行选项
        execute_choice "$choice"

        # 只有 0/99 才退出二级菜单，否则按回车刷新二级菜单
        if [[ "$choice" != "0" && "$choice" != "99" ]]; then
            read -rp $'\e[31m按回车刷新二级菜单...\e[0m' tmp
            clear
        else
            break
        fi
    done
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
        11) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/tun2socks.sh) ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/open_all_ports.sh) ;;
        13) curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-control.sh -o vps-control.sh && chmod +x vps-control.sh && ./vps-control.sh ;;
        14) sudo apt install unzip -y ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh) ;;
        16) sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent ;;
        17) sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent ;;
        18) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh) ;;
        19) if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi; bash install_panel.sh ed8484bec ;;
        20) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)" ;;
        21) if [ -f /usr/bin/curl ]; then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh; else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh; fi; bash install_panel.sh www.BTKaiXin.com ;;
        22) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        23) curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/update_local_apps.sh) ;;
        25) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/ggupdate_local_apps.sh) ;;
        26) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh ;;
        27) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
        28) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        29) bash <(curl -L -s menu.jinqians.com) ;;
        30) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        31) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh ;;
        32) apk add curl bash gzip openssl && bash <(curl -Ls https://raw.githubusercontent.com/StarVM-OpenSource/3x-ui-Apline/refs/heads/main/install.sh) ;;
        33) wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh ;;
        34) bash <(curl -Ls https://IP.Check.Place) -4 ;;
        35) bash <(curl -Ls https://IP.Check.Place) -6 ;;
        36) bash <(curl -Ls https://Net.Check.Place) -4 ;;
        37) bash <(curl -Ls https://Net.Check.Place) -6 ;;
        38) bash <(curl -sL https://run.NodeQuality.com) ;;
        39) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        40) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        41) bash <(wget -qO- bash.spiritlhl.net/ecs-cn) ;;
        42) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-cn.sh) ;;
        43) bash <(wget -qO- bash.spiritlhl.net/ecs-ping) ;;
        44) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh) ;;
        45) docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store ;;
        46) docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest ;;
        47) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        48) curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh ;;
        49) curl -fsSL https://raw.githubusercontent.com/iu683/app-store/main/vpsdocker.sh -o vpsdocker.sh && chmod +x vpsdocker.sh && ./vpsdocker.sh ;;
        50) curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh ;;
        51) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh ;;
        52) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh ;;
        53) bash <(curl -sL ss.hide.ss) ;;
        54) bash <(curl -sSL https://raw.githubusercontent.com/zeyu8023/vps_toolkit/main/install.sh) ;;
        55) curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose ;;
        56) curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh ;;
        57) curl -sL https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh -o Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh ;;
        58) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/Docker.sh) ;;
        59) bash <(curl -sL kejilion.sh) fd) ;;
        60) bash <(curl -fsSL https://raw.githubusercontent.com/1keji/AddIPv6/main/manage_nginx.sh) ;;
        61) bash <(curl -fsSL https://raw.githubusercontent.com/1keji/AddIPv6/main/manage_nginx_v6.sh) ;;
        88)
            echo -e "${yellow}正在更新脚本...${reset}"
            # 下载最新版本覆盖本地脚本
            curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-toolbox.sh -o "$INSTALL_PATH"
            if [[ $? -ne 0 ]]; then
                echo -e "${red}更新失败，请检查网络或GitHub地址${reset}"
                return 1
            fi
            chmod +x "$INSTALL_PATH"
            echo -e "${green}脚本已更新完成！${reset}"
            # 重新执行最新脚本
            exec bash "$INSTALL_PATH"
            ;;

        99) 
            echo -e "${yellow}正在卸载工具箱...${reset}"
            remove_shortcut
            rm -f "$INSTALL_PATH"
            echo -e "${green}卸载完成！${reset}"
            exit 0
            ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项${reset}"; return 1 ;;
    esac
}

# 自动创建快捷指令（只安装一次）
if [[ ! -f "$SHORTCUT_PATH" || ! -f "$SHORTCUT_PATH_UPPER" ]]; then
    install_shortcut
fi

# 主循环
while true; do
    show_main_menu
    echo -ne "${red}请输入要执行的编号 ${yellow}(0退出)${red}：${reset} "
    read -r main_choice
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
