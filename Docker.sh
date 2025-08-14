#!/bin/bash
# =========================
# VPS Docker 管理脚本（彩色美观界面）
# =========================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
PURPLE="\033[35m"
RESET="\033[0m"

root_use() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用 root 用户运行脚本${RESET}"
        exit 1
    fi
}

# ================== 国家检测 ==================
detect_country() {
    local country=$(curl -s --max-time 5 ipinfo.io/country)
    if [[ "$country" == "CN" ]]; then
        echo "CN"
    else
        echo "OTHER"
    fi
}

# ================== Docker 安装/更新/卸载 ==================
docker_install() {
    root_use
    local country=$(detect_country)
    echo -e "${CYAN}检测到国家: $country${RESET}"
    if [ "$country" = "CN" ]; then
        echo -e "${YELLOW}使用国内源安装 Docker...${RESET}"
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

    echo -e "${YELLOW}启动 Docker 守护进程...${RESET}"
    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl enable docker
        systemctl start docker
    else
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi

    # 开机自启
    if command -v systemctl &>/dev/null; then
        if ! systemctl list-unit-files | grep -q "^docker.service"; then
            echo "[Unit]
Description=Docker Daemon
After=network.target

[Service]
ExecStart=/usr/bin/dockerd
Restart=always
StartLimitInterval=0

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/docker.service
            systemctl daemon-reload
            systemctl enable docker
        fi
    else
        # rc.local
        if [ ! -f /etc/rc.local ]; then
            echo -e "#!/bin/sh -e\ndockerd >/dev/null 2>&1 &\nexit 0" > /etc/rc.local
            chmod +x /etc/rc.local
        fi
    fi

    echo -e "${GREEN}Docker 安装完成并启动${RESET}"
}

docker_update() {
    root_use
    echo -e "${YELLOW}更新 Docker...${RESET}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl restart docker
    else
        pkill dockerd 2>/dev/null
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi
    echo -e "${GREEN}Docker 更新完成${RESET}"
}

docker_uninstall() {
    root_use
    echo -e "${RED}卸载 Docker...${RESET}"
    systemctl stop docker 2>/dev/null
    systemctl disable docker 2>/dev/null
    pkill dockerd 2>/dev/null
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    yum remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    rm -rf /var/lib/docker /etc/docker /var/lib/containerd
    echo -e "${GREEN}Docker 已卸载${RESET}"
}

# ================== IPv6 ==================
docker_ipv6_on() {
    root_use
    mkdir -p /etc/docker
    jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}' /etc/docker/daemon.json 2>/dev/null >/etc/docker/daemon.json.tmp || \
        echo '{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}' > /etc/docker/daemon.json.tmp
    mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl restart docker
    else
        pkill dockerd 2>/dev/null
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi
    echo -e "${GREEN}Docker IPv6 已开启${RESET}"
}

docker_ipv6_off() {
    root_use
    if [ -f /etc/docker/daemon.json ]; then
        jq 'del(.ipv6) | del(.["fixed-cidr-v6"])' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp
        mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
        if systemctl list-unit-files | grep -q "^docker.service"; then
            systemctl restart docker
        else
            pkill dockerd 2>/dev/null
            dockerd >/dev/null 2>&1 &
            sleep 5
        fi
        echo -e "${GREEN}Docker IPv6 已关闭${RESET}"
    else
        echo -e "${YELLOW}Docker 配置文件不存在${RESET}"
    fi
}

# ================== 开放端口 ==================
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
        echo -e "${RED}Docker 未安装${RESET}"
        return
    fi
    while true; do
        clear
        echo -e "${CYAN}===== Docker 容器列表 =====${RESET}"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo -e "${YELLOW}1. 创建 2. 启动 3. 停止 4. 删除 5. 重启${RESET}"
        echo -e "${YELLOW}6. 启动所有 7. 停止所有 8. 删除所有 9. 重启所有${RESET}"
        echo -e "${YELLOW}11. 进入容器 12. 查看日志 0. 返回${RESET}"
        read -p "选择: " choice
        case $choice in
            1) read -p "输入创建命令: " cmd; $cmd ;;
            2) read -p "输入容器名: " name; docker start $name ;;
            3) read -p "输入容器名: " name; docker stop $name ;;
            4) read -p "输入容器名: " name; docker rm -f $name ;;
            5) read -p "输入容器名: " name; docker restart $name ;;
            6) docker start $(docker ps -a -q) ;;
            7) docker stop $(docker ps -q) ;;
            8) read -p "确定删除所有容器? (Y/N): " c; [[ $c =~ [Yy] ]] && docker rm -f $(docker ps -a -q) ;;
            9) docker restart $(docker ps -q) ;;
            11) read -p "输入容器名: " name; docker exec -it $name /bin/sh ;;
            12) read -p "输入容器名: " name; docker logs $name ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# ================== 镜像管理 ==================
docker_image() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker 未安装${RESET}"
        return
    fi
    while true; do
        clear
        echo -e "${CYAN}===== Docker 镜像列表 =====${RESET}"
        docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
        echo ""
        echo -e "${YELLOW}1. 拉取 2. 更新 3. 删除 4. 删除所有 0. 返回${RESET}"
        read -p "选择: " choice
        case $choice in
            1) read -p "镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            2) read -p "镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            3) read -p "镜像名: " imgs; for img in $imgs; do docker rmi -f $img; done ;;
            4) read -p "确定删除所有镜像? (Y/N): " c; [[ $c =~ [Yy] ]] && docker rmi -f $(docker images -q) ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# ================== 主菜单 ==================
main_menu() {
    root_use
    while true; do
        clear
        echo -e "${PURPLE}================ VPS Docker 管理菜单 ================${RESET}"
        echo -e "${CYAN}1. 安装 Docker${RESET}"
        echo -e "${CYAN}2. 更新 Docker${RESET}"
        echo -e "${CYAN}3. 卸载 Docker${RESET}"
        echo -e "${CYAN}4. 容器管理${RESET}"
        echo -e "${CYAN}5. 镜像管理${RESET}"
        echo -e "${CYAN}6. 开启 IPv6${RESET}"
        echo -e "${CYAN}7. 关闭 IPv6${RESET}"
        echo -e "${CYAN}8. 开放所有端口${RESET}"
        echo -e "${CYAN}0. 退出${RESET}"
        read -p "选择: " choice
        case $choice in
            1) docker_install ;;
            2) docker_update ;;
            3) docker_uninstall ;;
            4) docker_ps ;;
            5) docker_image ;;
            6) docker_ipv6_on ;;
            7) docker_ipv6_off ;;
            8) open_all_ports ;;
            0) exit 0 ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

main_menu
