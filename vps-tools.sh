#!/bin/bash

# ========== 配置 ==========
SCRIPT_PATH=$(readlink -f "$0")
LINK_PATH="/usr/local/bin/m"

# 创建 m / M 快捷启动
if [[ ! -L "$LINK_PATH" ]]; then
    sudo ln -sf "$SCRIPT_PATH" "$LINK_PATH"
    sudo ln -sf "$SCRIPT_PATH" "/usr/local/bin/M"
fi

# 彩虹渐变颜色数组
RAINBOW=(31 33 32 36 34 35)

# 打印彩虹渐变文字
rainbow_text() {
    local text="$1"
    local len=${#text}
    local out=""
    for ((i=0; i<len; i++)); do
        local color=${RAINBOW[i % ${#RAINBOW[@]}]}
        out+="\033[1;${color}m${text:i:1}"
    done
    out+="\033[0m"
    echo -e "$out"
}

# 菜单数据（编号|名称|命令）
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
    "12|WARP|wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]"
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
    "U|卸载工具箱|sudo rm -f \"$SCRIPT_PATH\" \"$LINK_PATH\" /usr/local/bin/M && echo '已卸载工具箱及快捷启动'"
)

# 打印菜单
print_menu() {
    clear
    rainbow_text "╔══════════════════════════════════════════════════════════════════════════╗"
    rainbow_text "║                🌟 服务器工具箱（四列彩虹渐变版） 🌟                 ║"
    rainbow_text "╠══════════════════════════════════════════════════════════════════════════╣"

    local cols=4
    local width=20
    local count=0
    local line=""
    for item in "${MENU_ITEMS[@]}"; do
        IFS="|" read -r num name cmd <<< "$item"
        entry="$(printf "\033[1;33m%2s\033[0m. %-*s" "$num" $((width-4)) "$name")"
        line+="$entry"
        ((count++))
        if (( count % cols == 0 )); then
            rainbow_text "║ $line ║"
            line=""
        fi
    done
    if [[ -n "$line" ]]; then
        while (( count % cols != 0 )); do
            line+="$(printf "%-${width}s" " ")"
            ((count++))
        done
        rainbow_text "║ $line ║"
    fi
    rainbow_text "╚══════════════════════════════════════════════════════════════════════════╝"
}

# 主循环
while true; do
    print_menu
    read -rp "请输入序号执行（或 Q 退出）: " choice
    [[ "$choice" =~ ^[Qq]$ ]] && exit 0
    for item in "${MENU_ITEMS[@]}"; do
        IFS="|" read -r num name cmd <<< "$item"
        if [[ "$choice" == "$num" ]]; then
            eval "$cmd"
            read -rp "按回车返回菜单..."
            break
        fi
    done
done
