#!/bin/bash
# VPS Docker 管理脚本（美化菜单 + 自动检测国内/国外源 + 安装/更新/卸载 + 容器/镜像/IPv6/开放端口 + 开机自启）

# ================== 颜色定义 ==================
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
MAGENTA="\033[35m"
RESET="\033[0m"

root_use() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用 root 用户运行脚本${RESET}"
        exit 1
    fi
}

# ================== 自动检测国内/国外 ==================
detect_country() {
    local country=$(curl -s --max-time 5 ipinfo.io/country)
    if [[ "$country" == "CN" ]]; then
        echo "CN"
    else
        echo "OTHER"
    fi
}

# ================== Docker 操作 ==================
docker_install() {
    root_use
    local country=$(detect_country)
    echo "检测到国家: $country"
    if [ "$country" = "CN" ]; then
        echo -e "${YELLOW}使用国内加速安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        mkdir -p /etc/docker
        tee /etc/docker/daemon.json > /dev/null << EOF
{
  "registry-mirrors": [
    "https://docker.0.unsee.tech",
    "https://docker.1panel.live",
    "https://registry.dockermirror.com",
    "https://docker.m.daocloud.io"
  ]
}
EOF
    else
        echo -e "${YELLOW}使用官方源安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | sh
    fi

    # 启动 Docker 并开机自启
    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl enable docker
        systemctl start docker
    else
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi

    echo -e "${GREEN}Docker 安装完成并已启动${RESET}"
}

docker_update() {
    root_use
    echo -e "${YELLOW}正在更新 Docker...${RESET}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl restart docker
    else
        pkill dockerd 2>/dev/null
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi
    echo -e "${GREEN}Docker 更新完成并已启动${RESET}"
}

docker_uninstall() {
    root_use
    echo -e "${RED}正在卸载 Docker...${RESET}"
    systemctl stop docker 2>/dev/null
    systemctl disable docker 2>/dev/null
    pkill dockerd 2>/dev/null
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    yum remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    rm -rf /var/lib/docker /etc/docker /var/lib/containerd
    echo -e "${GREEN}Docker 已卸载${RESET}"
}

# ================== IPv6 管理 ==================
docker_ipv6_on() {
    root_use
    mkdir -p /etc/docker
    jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}' /etc/docker/daemon.json 2>/dev/null >/etc/docker/daemon.json.tmp || \
        echo '{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}' > /etc/docker/daemon.json.tmp
    mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    systemctl restart docker 2>/dev/null || dockerd >/dev/null 2>&1 &
    echo -e "${GREEN}Docker IPv6 已开启${RESET}"
}

docker_ipv6_off() {
    root_use
    if [ -f /etc/docker/daemon.json ]; then
        jq 'del(.ipv6) | del(.["fixed-cidr-v6"])' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp
        mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
        systemctl restart docker 2>/dev/null || dockerd >/dev/null 2>&1 &
        echo -e "${GREEN}Docker IPv6 已关闭${RESET}"
    else
        echo -e "${YELLOW}Docker 配置文件不存在${RESET}"
    fi
}

# ================== 开放所有端口 ==================
open_all_ports() {
    root_use
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    echo -e "${GREEN}已开放所有端口${RESET}"
}

# ================== 容器管理 ==================
docker_ps() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker 未安装，请先安装${RESET}"
        return
    fi
    while true; do
        clear
        echo -e "${CYAN}===== Docker 容器管理 =====${RESET}"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo -e "${MAGENTA}1.${RESET} 创建新容器   ${MAGENTA}2.${RESET} 启动容器   ${MAGENTA}3.${RESET} 停止容器"
        echo -e "${MAGENTA}4.${RESET} 删除容器     ${MAGENTA}5.${RESET} 重启容器   ${MAGENTA}6.${RESET} 启动所有"
        echo -e "${MAGENTA}7.${RESET} 停止所有     ${MAGENTA}8.${RESET} 删除所有   ${MAGENTA}9.${RESET} 重启所有"
        echo -e "${MAGENTA}11.${RESET} 进入容器    ${MAGENTA}12.${RESET} 查看日志  ${MAGENTA}13.${RESET} 查看网络"
        echo -e "${MAGENTA}14.${RESET} 查看占用    ${MAGENTA}0.${RESET} 返回"
        read -p "请选择: " choice
        case $choice in
            1) read -p "请输入创建命令: " cmd; $cmd ;;
            2) read -p "请输入容器名: " name; docker start $name ;;
            3) read -p "请输入容器名: " name; docker stop $name ;;
            4) read -p "请输入容器名: " name; docker rm -f $name ;;
            5) read -p "请输入容器名: " name; docker restart $name ;;
            6) docker start $(docker ps -a -q) ;;
            7) docker stop $(docker ps -q) ;;
            8) read -p "确定删除所有容器? (Y/N): " c; [[ $c =~ [Yy] ]] && docker rm -f $(docker ps -a -q) ;;
            9) docker restart $(docker ps -q) ;;
            11) read -p "请输入容器名: " name; docker exec -it $name /bin/sh ;;
            12) read -p "请输入容器名: " name; docker logs $name ;;
            13) docker ps -q | while read cid; do docker inspect --format '{{.Name}} {{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{$v.IPAddress}}{{end}}' $cid; done ;;
            14) docker stats --no-stream ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# ================== 镜像管理 ==================
docker_image() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker 未安装，请先安装${RESET}"
        return
    fi
    while true; do
        clear
        echo -e "${CYAN}===== Docker 镜像管理 =====${RESET}"
        docker image ls
        echo -e "${MAGENTA}1.${RESET} 拉取镜像   ${MAGENTA}2.${RESET} 更新镜像"
        echo -e "${MAGENTA}3.${RESET} 删除镜像   ${MAGENTA}4.${RESET} 删除所有镜像   ${MAGENTA}0.${RESET} 返回"
        read -p "选择操作: " choice
        case $choice in
            1) read -p "请输入镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            2) read -p "请输入镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            3) read -p "请输入镜像名: " imgs; for img in $imgs; do docker rmi -f $img; done ;;
            4) read -p "确定删除所有镜像? (Y/N): " c; [[ $c =~ [Yy] ]] && docker rmi -f $(docker images -q) ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# ================== 开机自启 Docker + 所有容器 ==================
docker_autorestart() {
    root_use
    echo -e "${YELLOW}创建 Docker 容器开机自启服务...${RESET}"
    tee /etc/systemd/system/docker-autostart.service > /dev/null << 'EOF'
[Unit]
Description=Start Docker and all containers on boot
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker start $(/usr/bin/docker ps -aq)
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable docker-autostart
    systemctl start docker-autostart
    echo -e "${GREEN}Docker 与所有容器已设置开机自启${RESET}"
}

# ================== 主菜单 ==================
main_menu() {
    root_use
    while true; do
        clear
        echo -e "${CYAN}====================================${RESET}"
        echo -e "${GREEN}         VPS Docker 管理菜单        ${RESET}"
        echo -e "${CYAN}====================================${RESET}"
        echo -e "${YELLOW}Docker 操作:${RESET}"
        echo -e " 1. 安装 Docker"
        echo -e " 2. 更新 Docker"
        echo -e " 3. 卸载 Docker"
        echo -e "${YELLOW}容器/镜像管理:${RESET}"
        echo -e " 4. 容器管理"
        echo -e " 5. 镜像管理"
        echo -e "${YELLOW}系统/网络操作:${RESET}"
        echo -e " 6. 开启 IPv6"
        echo -e " 7. 关闭 IPv6"
        echo -e " 8. 开放所有端口"
        echo -e " 9. 设置 Docker + 容器开机自启"
        echo -e " 0. 退出"
        echo -e "${CYAN}====================================${RESET}"
        read -p "请选择: " choice
        case $choice in
            1) docker_install ;;
            2) docker_update ;;
            3) docker_uninstall ;;
            4) docker_ps ;;
            5) docker_image ;;
            6) docker_ipv6_on ;;
            7) docker_ipv6_off ;;
            8) open_all_ports ;;
            9) docker_autorestart ;;
            0) exit 0 ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

main_menu
