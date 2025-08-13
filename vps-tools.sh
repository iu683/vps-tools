#!/bin/bash

INSTALL_PATH="$HOME/vps-toolbox.sh"
SHORTCUT_PATH="/usr/local/bin/m"

green="\033[32m"
reset="\033[0m"

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

show_menu() {
    clear
    rainbow_border "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_border "    📦 服务器工具箱 📦"
    rainbow_border "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${green}"
    echo -e "
  1. 更新源                  2. 更新curl
  3. 哪吒压缩包              4. 卸载哪吒探针
  5. v1关SSH                 6. v0关SSH
  7. DDNS                    8. HY2
  9. 3XUI                    10. 老王工具箱
 11. 科技lion                12. WARP
 13. SNELL                   14. 国外EZRealm
 15. 国内EZRealm             16. V0哪吒
 17. 一点科技                18. Sub-Store
 19. 宝塔面板                20. 1panel面板
 21. WEBSSH                  22. 宝塔开心版
 23. IP解锁-IPv4             24. IP解锁-IPv6
 25. 网络质量-IPv4           26. 网络质量-IPv6
 27. NodeQuality脚本         28. 本机信息
 29. DDWin10                 30. Poste.io 邮局
 31. 服务器优化              32. 流媒体解锁
 33. 融合怪测试              34. 安装 Docker Compose
 35. 3x-ui-alpines           36. 临时禁用IPv6
 37. 添加SWAP                38. TCP窗口调优
 39. gost                    40. 极光面板
 41. 安装Python              42. 自定义DNS解锁
 43. Docker备份和恢复        44. Docker容器迁移
 45. VPS Toolkit             46. NGINX反代
 47. OpenList                48. 哆啦A梦转发面板
 49. 国外三网测速            50. 国内三网测速
 51. 国外三网延迟测试        52. 国内三网延迟测试
 88. VPS 管理                99. 卸载工具箱
  0. 退出
"
    rainbow_border "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${reset}"
}

install_shortcut() {
    echo "创建快捷指令 m"
    local script_path
    script_path=$(realpath "$0")
    echo "#!/bin/bash" | sudo tee "$SHORTCUT_PATH" >/dev/null
    echo "bash \"$script_path\"" | sudo tee -a "$SHORTCUT_PATH" >/dev/null
    sudo chmod +x "$SHORTCUT_PATH"
}

remove_shortcut() {
    if [ -f "$SHORTCUT_PATH" ]; then
        echo "删除快捷指令 m"
        sudo rm -f "$SHORTCUT_PATH"
    fi
}

execute_choice() {
    case "$1" in
        1) sudo apt update ;;
        2) sudo apt install curl -y ;;
        3) sudo apt install unzip -y ;;
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
        19) if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi; bash install_panel.sh ed8484bec ;;
        20) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)" ;;
        21) docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest ;;
        22) if [ -f /usr/bin/curl ]; then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh; else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh; fi; bash install_panel.sh www.BTKaiXin.com ;;
        23) bash <(curl -Ls https://IP.Check.Place) -4 ;;
        24) bash <(curl -Ls https://IP.Check.Place) -6 ;;
        25) bash <(curl -Ls https://Net.Check.Place) -4 ;;
        26) bash <(curl -Ls https://Net.Check.Place) -6 ;;
        27) bash <(curl -sL https://run.NodeQuality.com) ;;
        28) bash <(curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vpsinfo.sh) ;;
        29) bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang "cn" ;;
        30) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        31) bash <(curl -sL ss.hide.ss) ;;
        32) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        33) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        34) sudo apt install docker-compose-plugin -y ;;
        35) apk add curl bash gzip openssl && bash <(curl -Ls https://raw.githubusercontent.com/StarVM-OpenSource/3x-ui-Apline/refs/heads/main/install.sh) ;;
        36) sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 ;;
        37) wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh ;;
        38) wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh ;;
        39) wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh ;;
        40) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        41) curl -O https://raw.githubusercontent.com/lx969788249/lxspacepy/master/pyinstall.sh && chmod +x pyinstall.sh && ./pyinstall.sh ;;
        42) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/media_dns.sh) ;;
        43) curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh ;;
        44) curl -O https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh ;;
        45) bash <(curl -sSL https://raw.githubusercontent.com/zeyu8023/vps_toolkit/main/install.sh) ;;
        46) bash <(curl -sL kejilion.sh) fd ;;
        47) curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh ;;
        48) curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        49) bash <(wget -qO- bash.spiritlhl.net/ecs-net) ;;
        50) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-net.sh) ;;
        51) bash <(wget -qO- bash.spiritlhl.net/ecs-ping) ;;
        52) bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh) ;;
        88)
            curl -fsSL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-control.sh -o vps-control.sh
            chmod +x vps-control.sh
            ./vps-control.sh
            ;;
        99)
            echo "卸载工具箱..."
            rm -f "$INSTALL_PATH"
            remove_shortcut
            echo "卸载完成"
            exit 0
            ;;
        0)
            echo "退出"
            exit 0
            ;;
        *)
            echo "无效选项"
            ;;
    esac
}

while true; do
    show_menu
    read -p "请输入选项编号: " choice
    execute_choice "$choice"
    read -p "按回车返回菜单..."

    if [ ! -f "$SHORTCUT_PATH" ]; then
        install_shortcut
    fi
done
