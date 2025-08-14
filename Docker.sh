#!/bin/bash
# VPS Docker 管理脚本（自动检测国内/国外源 + 安装/更新/卸载/容器/镜像/IPv6/iptables/crontab）

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
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

# ================== 安装 Docker ==================
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

    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl enable docker
        systemctl start docker
    else
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi
    echo -e "${GREEN}Docker 安装完成${RESET}"
}

docker_update() {
    root_use
    echo -e "${YELLOW}正在更新 Docker...${RESET}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    if systemctl list-unit-files | grep -q "^docker.service"; then
        systemctl restart docker
    else
        pkill dockerd
        dockerd >/dev/null 2>&1 &
        sleep 5
    fi
    echo -e "${GREEN}Docker 更新完成${RESET}"
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
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4
    echo -e "${GREEN}已开放所有端口并保存规则${RESET}"
}

# ================== 容器管理 ==================
docker_ps() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker 未安装，请先安装${RESET}"
        return
    fi
    while true; do
        clear
        echo "Docker 容器列表"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "1. 创建新容器 2. 启动容器 3. 停止容器 4. 删除容器 5. 重启容器"
        echo "6. 启动所有 7. 停止所有 8. 删除所有 9. 重启所有"
        echo "11. 进入容器 12. 查看日志 13. 查看网络 14. 查看占用"
        echo "0. 返回"
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
        echo "Docker 镜像列表"
        docker image ls
        echo "1. 拉取镜像 2. 更新镜像 3. 删除镜像 4. 删除所有镜像 0. 返回"
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

# ================== crontab 自动安装 ==================
check_crontab_installed() {
    if ! command -v crontab >/dev/null 2>&1; then
        install_crontab
    else
        echo -e "${GREEN}crontab 已安装${RESET}"
    fi
}

install_crontab() {
    root_use
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|kali)
                apt update
                apt install -y cron
                systemctl enable cron
                systemctl start cron
                ;;
            centos|rhel|almalinux|rocky)
                yum install -y cronie
                systemctl enable crond
                systemctl start crond
                ;;
            fedora)
                dnf install -y cronie
                systemctl enable crond
                systemctl start crond
                ;;
            alpine)
                apk add --no-cache cronie
                rc-update add crond
                rc-service crond start
                ;;
            *)
                echo -e "${RED}不支持的发行版: $ID${RESET}"
                return
                ;;
        esac
        echo -e "${GREEN}crontab 已安装并启动服务${RESET}"
    else
        echo -e "${RED}无法确定操作系统，crontab 安装失败${RESET}"
        return
    fi
}

# ================== 主菜单 ==================
main_menu() {
    root_use
    while true; do
        clear
        echo "===== VPS Docker 管理菜单 ====="
        echo "1. 安装 Docker（自动检测国内/国外源）"
        echo "2. 更新 Docker"
        echo "3. 卸载 Docker"
        echo "4. 容器管理"
        echo "5. 镜像管理"
        echo "6. 开启 IPv6"
        echo "7. 关闭 IPv6"
        echo "8. 开放所有端口并保存规则"
        echo "9. 安装/检查 crontab"
        echo "0. 退出"
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
            9) check_crontab_installed ;;
            0) exit 0 ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

main_menu
