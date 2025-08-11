#!/bin/bash
# VPS 工具箱 - 彩色菜单版
# 适合 Ubuntu/Debian，需 root 权限运行

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

# 检查 root
if [ "$(id -u)" != "0" ]; then
  echo -e "${RED}请用root权限运行脚本！${RESET}"
  exit 1
fi

pause(){
  read -rp "$(echo -e ${YELLOW}"按回车返回菜单...${RESET}")"
}

# 获取脚本自身的绝对路径
SCRIPT_PATH=$(realpath "$0")

while true; do
  clear
  echo -e "${BOLD}${BLUE}====================== VPS 一键工具箱 v2.0 ======================${RESET}"
  echo -e "${YELLOW}支持: Ubuntu/Debian | 快捷指令: M (通过选项28设置后可用)${RESET}"
  echo -e "${BOLD}${BLUE}-------------------------------------------------------------------${RESET}"

  # --- 双列菜单 ---
  printf "%-38s %s\n" "${YELLOW} 1.${RESET} 更新源" "${YELLOW}15.${RESET} 国内 EZRealm"
  printf "%-38s %s\n" "${YELLOW} 2.${RESET} 安装 curl" "${YELLOW}16.${RESET} V0 哪吒"
  printf "%-38s %s\n" "${YELLOW} 3.${RESET} 安装 unzip" "${YELLOW}17.${RESET} 一点科技"
  printf "%-38s %s\n" "${YELLOW} 4.${RESET} 卸载哪吒探针" "${YELLOW}18.${RESET} Sub-Store Docker"
  printf "%-38s %s\n" "${YELLOW} 5.${RESET} v1 哪吒关闭SSH" "${YELLOW}19.${RESET} 宝塔面板"
  printf "%-38s %s\n" "${YELLOW} 6.${RESET} v0 哪吒关闭SSH" "${YELLOW}20.${RESET} 1panel 面板"
  printf "%-38s %s\n" "${YELLOW} 7.${RESET} DDNS 脚本" "${YELLOW}21.${RESET} WEBSSH Docker"
  printf "%-38s %s\n" "${YELLOW} 8.${RESET} 安装 HY2" "${YELLOW}22.${RESET} 宝塔开心版"
  printf "%-38s %s\n" "${YELLOW} 9.${RESET} 安装 3XUI" "${YELLOW}23.${RESET} IP 解锁 (IPv4)"
  printf "%-38s %s\n" "${YELLOW}10.${RESET} 老王工具箱" "${YELLOW}24.${RESET} IP 解锁 (IPv6)"
  printf "%-38s %s\n" "${YELLOW}11.${RESET} 科技 lion" "${YELLOW}25.${RESET} 网络质量 (IPv4)"
  printf "%-38s %s\n" "${YELLOW}12.${RESET} WARP" "${YELLOW}26.${RESET} 网络质量 (IPv6)"
  printf "%-38s %s\n" "${YELLOW}13.${RESET} SNELL" "${YELLOW}27.${RESET} NodeQuality 脚本"
  printf "%-38s %s\n" "${YELLOW}14.${RESET} 国外 EZRealm" ""

  echo -e "${BOLD}${BLUE}-------------------------------------------------------------------${RESET}"
  printf "%-38s %s\n" "${GREEN}28.${RESET} 设置快捷指令 'M'" "${RED} 0.${RESET} 退出工具箱"
  echo -e "${BOLD}${BLUE}===================================================================${RESET}"

  read -rp "请输入选项编号: " choice
  echo

  case $choice in
    1)
      echo -e "${GREEN}正在更新源...${RESET}"
      sudo apt update
      pause
      ;;
    2)
      echo -e "${GREEN}安装 curl...${RESET}"
      sudo apt install curl -y
      pause
      ;;
    3)
      echo -e "${GREEN}安装 unzip...${RESET}"
      apt install unzip -y
      pause
      ;;
    4)
      echo -e "${GREEN}卸载哪吒探针...${RESET}"
      bash <(curl -fsSL https://raw.githubusercontent.com/SimonGino/Config/master/sh/uninstall_nezha_agent.sh)
      pause
      ;;
    5)
      echo -e "${GREEN}v1 哪吒关闭 SSH 命令执行...${RESET}"
      sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml && systemctl restart nezha-agent
      pause
      ;;
    6)
      echo -e "${GREEN}v0 哪吒关闭 SSH 命令执行...${RESET}"
      sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload && systemctl restart nezha-agent
      pause
      ;;
    7)
      echo -e "${GREEN}运行 DDNS 脚本...${RESET}"
      bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh)
      pause
      ;;
    8)
      echo -e "${GREEN}安装 HY2 (Hysteria2)...${RESET}"
      wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh
      pause
      ;;
    9)
      echo -e "${GREEN}安装 3XUI 面板...${RESET}"
      bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
      pause
      ;;
    10)
      echo -e "${GREEN}启动老王工具箱...${RESET}"
      curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh
      pause
      ;;
    11)
      echo -e "${GREEN}启动科技 lion...${RESET}"
      curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
      pause
      ;;
    12)
      echo -e "${GREEN}启动 WARP...${RESET}"
      wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
      pause
      ;;
    13)
      echo -e "${GREEN}启动 SNELL...${RESET}"
      bash <(curl -L -s menu.jinqians.com)
      pause
      ;;
    14)
      echo -e "${GREEN}启动国外 EZRealm...${RESET}"
      wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/realm.sh && chmod +x realm.sh && ./realm.sh
      pause
      ;;
    15)
      echo -e "${GREEN}启动国内 EZRealm...${RESET}"
      wget -N https://raw.githubusercontent.com/shiyi11yi/EZRealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh
      pause
      ;;
    16)
      echo -e "${GREEN}启动 V0 哪吒...${RESET}"
      bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh)
      pause
      ;;
    17)
      echo -e "${GREEN}启动一点科技...${RESET}"
      wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh
      pause
      ;;
    18)
      echo -e "${GREEN}启动 Sub-Store Docker 容器...${RESET}"
      docker run -it -d --restart=always -e "SUB_STORE_CRON=0 0 * * *" -e SUB_STORE_FRONTEND_BACKEND_PATH=/2cXaAxRGfddmGz2yx1wA -p 3001:3001 -v /root/sub-store-data:/opt/app/data --name sub-store xream/sub-store
      pause
      ;;
    19)
      echo -e "${GREEN}安装宝塔面板...${RESET}"
      if [ -f /usr/bin/curl ];then
        curl -sSO https://download.bt.cn/install/install_panel.sh
      else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
      fi
      bash install_panel.sh ed8484bec
      pause
      ;;
    20)
      echo -e "${GREEN}安装1panel面板...${RESET}"
      bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"
      pause
      ;;
    21)
      echo -e "${GREEN}启动 WEBSSH Docker 容器...${RESET}"
      docker run -d --name webssh --restart always -p 8888:8888 cmliu/webssh:latest
      pause
      ;;
    22)
      echo -e "${GREEN}安装宝塔开心版...${RESET}"
      if [ -f /usr/bin/curl ];then
        curl -sSO http://bt95.btkaixin.net/install/install_panel.sh
      else
        wget -O install_panel.sh http://bt95.btkaixin.net/install/install_panel.sh
      fi
      bash install_panel.sh www.BTKaiXin.com
      pause
      ;;
    23)
      echo -e "${GREEN}IP 解锁 IPv4...${RESET}"
      bash <(curl -Ls https://IP.Check.Place) -4
      pause
      ;;
    24)
      echo -e "${GREEN}IP 解锁 IPv6...${RESET}"
      bash <(curl -Ls https://IP.Check.Place) -6
      pause
      ;;
    25)
      echo -e "${GREEN}检测网络质量 IPv4...${RESET}"
      bash <(curl -Ls https://Net.Check.Place) -4
      pause
      ;;
    26)
      echo -e "${GREEN}检测网络质量 IPv6...${RESET}"
      bash <(curl -Ls https://Net.Check.Place) -6
      pause
      ;;
    27)
      echo -e "${GREEN}运行 NodeQuality 脚本...${RESET}"
      bash <(curl -sL https://run.NodeQuality.com)
      pause
      ;;
    # --- 新增功能：设置快捷指令 ---
    28)
      echo -e "${GREEN}开始设置快捷指令 'M'...${RESET}"
      BASHRC_FILE="$HOME/.bashrc"
      ALIAS_CMD="alias M='sudo ${SCRIPT_PATH}'"
      
      # 检查 .bashrc 文件中是否已存在该别名
      if grep -qF "${ALIAS_CMD}" "${BASHRC_FILE}"; then
        echo -e "${YELLOW}快捷指令 'M' 已经设置过了，无需重复操作。${RESET}"
      else
        # 将别名命令追加到 .bashrc 文件末尾
        echo "" >> "${BASHRC_FILE}"
        echo "# VPS Toolbox Alias" >> "${BASHRC_FILE}"
        echo "${ALIAS_CMD}" >> "${BASHRC_FILE}"
        echo -e "${GREEN}快捷指令 'M' 设置成功！${RESET}"
        echo -e "${YELLOW}请运行 'source ~/.bashrc' 或重新登录SSH使其生效。${RESET}"
      fi
      pause
      ;;
    # --- 新增功能结束 ---
    0)
      echo -e "${RED}退出工具箱${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}无效选项，请输入正确编号！${RESET}"
      pause
      ;;
  esac
done
