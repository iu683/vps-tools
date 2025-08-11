#!/bin/bash

#================= 配置部分 =================#
# 你的 GitHub 直链（替换成你的仓库链接）
GITHUB_URL="https://raw.githubusercontent.com/用户名/仓库名/main/vps-tools.sh"

# 安装快捷启动 m（如果不存在）
if [[ ! -f /usr/local/bin/m ]]; then
    echo "注册快捷启动命令 m..."
    echo "bash <(curl -fsSL $GITHUB_URL)" > /usr/local/bin/m
    chmod +x /usr/local/bin/m
fi

# 彩虹颜色数组
COLORS=(
    "\033[38;5;196m" "\033[38;5;202m" "\033[38;5;226m"
    "\033[38;5;46m"  "\033[38;5;51m"  "\033[38;5;21m"
    "\033[38;5;93m"  "\033[38;5;201m"
)
RESET="\033[0m"
NUM="\033[1;33m"
TITLE="\033[1;37m"

# 菜单（编号|名称|命令）
MENU_ITEMS=(
    "1|更新源|sudo apt update"
    "2|更新curl|sudo apt install curl"
    "3|哪吒压缩包|apt install unzip -y"
    "4|卸载哪吒探针|bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh)"
    "5|v1关SSH|sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent"
    "6|v0关SSH|sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent"
    "7|DDNS|bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh)"
    "8|HY2|wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh"
    "9|3XUI|bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)"
    "10|老王工具箱|curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh"
    "11|科技lion|curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh"
    "12|WARP|wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh"
    "13|SNELL|bash <(curl -L -s menu.jinqians.com)"
    "14|国外EZRealm|wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh"
    "15|国内EZRealm|wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh"
    "16|V0哪吒|bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh)"
    "17|一点科技|wget -O 1keji.sh \"https://www.1keji.net\" && chmod +x 1keji.sh && ./1keji.sh"
    "18|Sub-Store|docker run -it -d --restart=always -e \"SUB_STORE_CRON=0 0 * * *\" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store"
    "19|宝塔面板|if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec"
    "20|1panel面板|bash -c \"\$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)\""
    "21|WEBSSH|docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest"
    "22|宝塔开心版|if [ -f /usr/bin/curl ];then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh;else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh;fi;bash install_panel.sh www.BTKaiXin.com"
    "23|IP解锁-IPv4|bash <(curl -Ls https://IP.Check.Place) -4"
    "24|IP解锁-IPv6|bash <(curl -Ls https://IP.Check.Place) -6"
    "25|网络质量-IPv4|bash <(curl -Ls https://Net.Check.Place) -4"
    "26|网络质量-IPv6|bash <(curl -Ls https://Net.Check.Place) -6"
    "27|NodeQuality|bash <(curl -sL https://run.NodeQuality.com)"
    "0|退出|exit 0"
    "99|卸载工具箱|rm -f /usr/local/bin/m && echo '已卸载 m 快捷键' && exit 0"
)

# 彩虹边框打印
print_border() {
    local text="$1"
    local len=${#text}
    local border=""
    for ((i=0; i<len; i++)); do
        border+="${COLORS[i % ${#COLORS[@]}]}${text:i:1}${RESET}"
    done
    echo -e "$border"
}

# 打印菜单
print_menu() {
    clear
    print_border "╔════════════════════════════════════════════════════════════════════════╗"
    print_border "║           🌈 VPS 多功能工具箱（双列彩虹版） 🌈                          ║"
    print_border "╠════════════════════════════════════════════════════════════════════════╣"
    local cols=2
    local width=38
    local count=0
    local line=""
    for item in "${MENU_ITEMS[@]}"; do
        IFS="|" read -r num name cmd <<< "$item"
        entry="$(printf "${NUM}%2s${RESET}. %-*s" "$num" $((width-6)) "$name")"
        line+="$entry"
        ((count++))
        if (( count % cols == 0 )); then
            print_border "║ $line ║"
            line=""
        fi
    done
    if [[ -n "$line" ]]; then
        while (( count % cols != 0 )); do
            line+="$(printf "%-${width}s" " ")"
            ((count++))
        done
        print_border "║ $line ║"
    fi
    print_border "╚════════════════════════════════════════════════════════════════════════╝"
}

# 运行
while true; do
    print_menu
    read -rp "请输入序号执行: " choice
    for item in "${MENU_ITEMS[@]}"; do
        IFS="|" read -r num name cmd <<< "$item"
        if [[ "$choice" == "$num" ]]; then
            eval "$cmd"
            read -rp "按回车返回菜单..."
            break
        fi
    done
done
