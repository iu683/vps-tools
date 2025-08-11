#!/bin/bash
# VPS 工具箱 - 双列彩虹边框版
# 支持 Ubuntu/Debian，需 root 权限运行

# 彩虹颜色
COLORS=(
  '\033[38;5;196m' # 红
  '\033[38;5;202m' # 橙
  '\033[38;5;226m' # 黄
  '\033[38;5;46m'  # 绿
  '\033[38;5;21m'  # 蓝
  '\033[38;5;93m'  # 靛
  '\033[38;5;201m' # 紫
)
RESET='\033[0m'
BOLD='\033[1m'

# 检查 root
if [ "$(id -u)" != "0" ]; then
  echo -e "\033[31m请用root权限运行脚本！\033[0m"
  exit 1
fi

pause(){
  read -rp "$(echo -e '\033[33m按回车返回菜单...\033[0m')"
}

# 生成彩虹边框
print_rainbow_border() {
  local text="$1"
  local border=""
  local len=${#text}
  local color_index=0
  for (( i=0; i<$len; i++ )); do
    border+="${COLORS[$color_index]}━${RESET}"
    ((color_index=(color_index+1)%${#COLORS[@]}))
  done
  echo -e "$border"
}

# 快捷启动命令（安装）
install_shortcut() {
  echo "curl -sSL https://example.com/vps-tool.sh | bash" > /usr/local/bin/vps-tool
  chmod +x /usr/local/bin/vps-tool
  echo -e "${COLORS[3]}快捷启动命令已安装，你可以直接输入 vps-tool 启动${RESET}"
}

# 卸载脚本
uninstall_toolbox() {
  rm -f /usr/local/bin/vps-tool
  echo -e "${COLORS[0]}已卸载工具箱快捷命令${RESET}"
  exit 0
}

while true; do
  clear
  TITLE=" VPS 多功能工具箱 "
  print_rainbow_border "$TITLE"
  echo -e "${BOLD}${TITLE}${RESET}"
  print_rainbow_border "$TITLE"

  echo
  echo -e "${COLORS[0]} 1.${RESET} 更新源           ${COLORS[1]} 2.${RESET} 安装 curl"
  echo -e "${COLORS[2]} 3.${RESET} 安装 unzip       ${COLORS[3]} 4.${RESET} 卸载哪吒探针"
  echo -e "${COLORS[4]} 5.${RESET} v1 关闭SSH       ${COLORS[5]} 6.${RESET} v0 关闭SSH"
  echo -e "${COLORS[6]} 7.${RESET} DDNS 脚本         ${COLORS[0]} 8.${RESET} 安装 HY2"
  echo -e "${COLORS[1]} 9.${RESET} 安装 3XUI         ${COLORS[2]}10.${RESET} 老王工具箱"
  echo -e "${COLORS[3]}11.${RESET} 科技 lion         ${COLORS[4]}12.${RESET} WARP"
  echo -e "${COLORS[5]}13.${RESET} SNELL            ${COLORS[6]}14.${RESET} 国外 EZRealm"
  echo -e "${COLORS[0]}15.${RESET} 国内 EZRealm      ${COLORS[1]}16.${RESET} V0 哪吒"
  echo -e "${COLORS[2]}17.${RESET} 一点科技         ${COLORS[3]}18.${RESET} Sub-Store Docker"
  echo -e "${COLORS[4]}19.${RESET} 宝塔面板         ${COLORS[5]}20.${RESET} 1panel 面板"
  echo -e "${COLORS[6]}21.${RESET} WEBSSH Docker    ${COLORS[0]}22.${RESET} 宝塔开心版"
  echo -e "${COLORS[1]}23.${RESET} IP解锁 IPv4      ${COLORS[2]}24.${RESET} IP解锁 IPv6"
  echo -e "${COLORS[3]}25.${RESET} 网络质量 IPv4    ${COLORS[4]}26.${RESET} 网络质量 IPv6"
  echo -e "${COLORS[5]}27.${RESET} NodeQuality 脚本"
  echo -e "${COLORS[6]}98.${RESET} 安装快捷启动命令"
  echo -e "${COLORS[0]}99.${RESET} 卸载脚本"
  echo -e "${COLORS[1]} 0.${RESET} 退出"
  echo

  read -rp "请输入选项编号: " choice
  echo

  case $choice in
    1) sudo apt update; pause ;;
    2) sudo apt install curl -y; pause ;;
    3) apt install unzip -y; pause ;;
    4) bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh); pause ;;
    5) sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent; pause ;;
    6) sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent; pause ;;
    7) bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh); pause ;;
    8) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh; pause ;;
    9) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); pause ;;
    10) curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh; pause ;;
    11) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh; pause ;;
    12) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh; pause ;;
    13) bash <(curl -L -s menu.jinqians.com); pause ;;
    14) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh; pause ;;
    15) wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh; pause ;;
    16) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh); pause ;;
    17) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh; pause ;;
    18) docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store; pause ;;
    19) curl -sSO https://download.bt.cn/install/install_panel.sh && bash install_panel.sh ed8484bec; pause ;;
    20) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"; pause ;;
    21) docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest; pause ;;
    22) curl -sSO http://bt95.btkaixin.net/install/install_panel.sh && bash install_panel.sh www.BTKaiXin.com; pause ;;
    23) bash <(curl -Ls https://IP.Check.Place) -4; pause ;;
    24) bash <(curl -Ls https://IP.Check.Place) -6; pause ;;
    25) bash <(curl -Ls https://Net.Check.Place) -4; pause ;;
    26) bash <(curl -Ls https://Net.Check.Place) -6; pause ;;
    27) bash <(curl -sL https://run.NodeQuality.com); pause ;;
    98) install_shortcut; pause ;;
    99) uninstall_toolbox ;;
    0) exit 0 ;;
    *) echo -e "\033[31m无效选项，请输入正确编号！\033[0m"; pause ;;
  esac
done
