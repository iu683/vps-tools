#!/bin/bash
# VPS 工具箱 - 优化彩色菜单版 + 快捷命令 m
# 适用于 Ubuntu / Debian，需 root 权限运行

# ========== 颜色定义 ==========
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

# ========== 检查 root ==========
if [ "$(id -u)" != "0" ]; then
  echo -e "${RED}请使用 root 权限运行脚本！${RESET}"
  exit 1
fi

# ========== 自动创建快捷命令 m ==========
if [ ! -f /usr/local/bin/m ]; then
  ln -sf "$(realpath "$0")" /usr/local/bin/m
  chmod +x /usr/local/bin/m
  echo -e "${GREEN}已创建快捷启动命令：m${RESET}"
fi

# ========== 函数 ==========
pause() {
  echo
  read -rp "$(echo -e "${YELLOW}按回车返回菜单...${RESET}")"
}

check_dep() {
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${YELLOW}正在安装依赖：${cmd}${RESET}"
      apt install -y "$cmd"
    fi
  done
}

# ========== 主菜单循环 ==========
while true; do
  clear
  echo -e "${BOLD}${BLUE}==== VPS 多功能工具箱 ====${RESET}"
  
  echo -e "${YELLOW} 系统管理 ${RESET}"
  echo "  1. 更新源"
  echo "  2. 安装 curl"
  echo "  3. 安装 unzip"
  
  echo -e "\n${YELLOW} 探针相关 ${RESET}"
  echo "  4. 卸载哪吒探针"
  echo "  5. v1 关闭 SSH 命令执行"
  echo "  6. v0 关闭 SSH 命令执行"
  echo " 16. 启动 V0 哪吒"
  
  echo -e "\n${YELLOW} 网络工具 ${RESET}"
  echo "  7. DDNS 脚本"
  echo "  8. 安装 Hysteria2"
  echo "  9. 安装 3XUI"
  echo " 12. WARP"
  echo " 13. SNELL"
  echo " 14. 国外 EZRealm"
  echo " 15. 国内 EZRealm"
  echo " 17. 一点科技"
  
  echo -e "\n${YELLOW} 面板相关 ${RESET}"
  echo " 19. 宝塔面板"
  echo " 20. 1panel 面板"
  echo " 22. 宝塔开心版"
  
  echo -e "\n${YELLOW} Docker 工具 ${RESET}"
  echo " 18. Sub-Store 容器"
  echo " 21. WEBSSH 容器"
  
  echo -e "\n${YELLOW} 测试与检测 ${RESET}"
  echo " 23. IP 解锁 (IPv4)"
  echo " 24. IP 解锁 (IPv6)"
  echo " 25. 网络质量 (IPv4)"
  echo " 26. 网络质量 (IPv6)"
  echo " 27. NodeQuality 脚本"
  
  echo -e "\n${RED}  0. 退出${RESET}"
  echo -e "${BOLD}${BLUE}==========================${RESET}"
  
  read -rp "请输入选项编号: " choice
  echo
  
  case $choice in
    1) apt update -y; pause ;;
    2) apt install -y curl; pause ;;
    3) apt install -y unzip; pause ;;
    4) check_dep curl; bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh); pause ;;
    5) sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent; pause ;;
    6) sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent; pause ;;
    7) check_dep wget; bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh); pause ;;
    8) check_dep wget; wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh; pause ;;
    9) check_dep curl; bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); pause ;;
    12) check_dep wget; wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh; pause ;;
    13) check_dep curl; bash <(curl -L -s menu.jinqians.com); pause ;;
    14) check_dep wget; wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh; pause ;;
    15) check_dep wget; wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh; pause ;;
    16) check_dep wget; bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh); pause ;;
    17) check_dep wget; wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh; pause ;;
    18) check_dep docker; docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store; pause ;;
    19) check_dep curl wget; if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi; bash install_panel.sh ed8484bec; pause ;;
    20) check_dep curl; bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"; pause ;;
    21) check_dep docker; docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest; pause ;;
    22) check_dep curl wget; if [ -f /usr/bin/curl ]; then curl -sSO http://bt95.btkaixin.net/install/install_panel.sh; else wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh; fi; bash install_panel.sh www.BTKaiXin.com; pause ;;
    23) check_dep curl; bash <(curl -Ls https://IP.Check.Place) -4; pause ;;
    24) check_dep curl; bash <(curl -Ls https://IP.Check.Place) -6; pause ;;
    25) check_dep curl; bash <(curl -Ls https://Net.Check.Place) -4; pause ;;
    26) check_dep curl; bash <(curl -Ls https://Net.Check.Place) -6; pause ;;
    27) check_dep curl; bash <(curl -sL https://run.NodeQuality.com); pause ;;
    0) echo -e "${RED}退出工具箱${RESET}"; exit 0 ;;
    *) echo -e "${RED}无效选项，请输入正确编号！${RESET}"; pause ;;
  esac
done
