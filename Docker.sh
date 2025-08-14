#!/bin/bash
# ========================================
# 一键 Docker 安装 & 管理脚本 (最终版)
# ========================================

# ---------------- 颜色定义 ----------------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

gl_hong=$RED
gl_lv=$GREEN
gl_huang=$YELLOW
gl_bai=$RESET

# ---------------- 公共函数 ----------------
root_use() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${gl_hong}请使用 root 权限运行脚本${gl_bai}"
        exit 1
    fi
}

install_pkg() {
    if ! command -v "$1" &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt update && apt install -y "$1"
        elif command -v yum &>/dev/null; then
            yum install -y "$1"
        elif command -v dnf &>/dev/null; then
            dnf install -y "$1"
        elif command -v apk &>/dev/null; then
            apk add --no-cache "$1"
        else
            echo -e "${gl_hong}无法自动安装 $1，请手动安装${gl_bai}"
        fi
    fi
}

systemctl_enable_start() {
    systemctl enable docker
    systemctl start docker
    systemctl restart docker
}

# ---------------- Docker 官方安装 + 国内加速 ----------------
docker_official_install() {
    echo -e "${gl_huang}正在通过官方脚本安装 Docker...${gl_bai}"
    curl -fsSL https://get.docker.com | sh

    local country=$(curl -s ipinfo.io/country)
    if [ "$country" = "CN" ]; then
        echo -e "${gl_lv}检测到中国大陆，配置国内加速源${gl_bai}"
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << EOF
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
        echo -e "${gl_lv}检测到非中国大陆，使用官方默认源${gl_bai}"
    fi

    systemctl_enable_start
    echo -e "${gl_lv}Docker 安装完成${gl_bai}"
}

docker_uninstall() {
    echo -e "${gl_hong}正在卸载 Docker...${gl_bai}"
    systemctl stop docker
    systemctl disable docker
    if command -v docker &>/dev/null; then
        apt-get remove -y docker docker-engine docker.io containerd runc &>/dev/null || true
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine containerd.io &>/dev/null || true
        dnf remove -y docker-ce docker-ce-cli containerd.io &>/dev/null || true
    fi
    rm -rf /var/lib/docker /etc/docker /var/run/docker.sock
    echo -e "${gl_lv}Docker 已成功卸载${gl_bai}"
}

# ---------------- crontab 自动安装 ----------------
check_crontab_installed() {
    if ! command -v crontab >/dev/null 2>&1; then
        install_crontab
    fi
}

install_crontab() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|kali)
                apt update
                apt install -y cron
                systemctl enable cron
                systemctl start cron
                ;;
            centos|rhel|almalinux|rocky|fedora)
                yum install -y cronie
                systemctl enable crond
                systemctl start crond
                ;;
            alpine)
                apk add --no-cache cronie
                rc-update add crond
                rc-service crond start
                ;;
            *)
                echo "不支持的发行版: $ID"
                return
                ;;
        esac
    else
        echo "无法确定操作系统。"
        return
    fi
    echo -e "${gl_lv}crontab 已安装且 cron 服务正在运行${gl_bai}"
}

# ---------------- IPv6 ----------------
docker_ipv6_on() {
    root_use
    install_pkg jq
    local CONFIG_FILE="/etc/docker/daemon.json"
    local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
        systemctl restart docker
    else
        local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")
        local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')
        local UPDATED_CONFIG
        if [[ "$CURRENT_IPV6" == "false" ]]; then
            UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
        else
            UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
        fi
        if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
            echo -e "${gl_huang}当前已开启 IPv6${gl_bai}"
        else
            echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
            systemctl restart docker
        fi
    fi
}

docker_ipv6_off() {
    root_use
    install_pkg jq
    local CONFIG_FILE="/etc/docker/daemon.json"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${gl_hong}配置文件不存在${gl_bai}"
        return
    fi
    local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")
    local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')
    local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')
    if [[ "$CURRENT_IPV6" == "false" ]]; then
        echo -e "${gl_huang}当前已关闭 IPv6${gl_bai}"
    else
        echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
        systemctl restart docker
        echo -e "${gl_lv}已成功关闭 IPv6${gl_bai}"
    fi
}

# ---------------- iptables 自动保存 ----------------
save_iptables_rules() {
    if command -v apt &>/dev/null; then
        install_pkg iptables-persistent
        netfilter-persistent save
    elif command -v yum &>/dev/null || command -v dnf &>/dev/null; then
        if command -v service &>/dev/null && service iptables status &>/dev/null; then
            service iptables save
        else
            iptables-save > /etc/sysconfig/iptables
        fi
    else
        iptables-save > /etc/iptables.rules
    fi
    echo -e "${gl_lv}iptables 规则已保存${gl_bai}"
}

# ---------------- 容器端口开放/关闭 ----------------
open_container_ports() {
    read -e -p "请输入容器名: " docker_name
    if ! docker ps -a --format '{{.Names}}' | grep -wq "$docker_name"; then
        echo -e "${gl_hong}容器不存在${gl_bai}"
        return
    fi
    ports=$(docker port "$docker_name" | awk -F'[:]' '{print $NF}' | uniq)
    ip_addr=$(hostname -I | awk '{print $1}')
    for port in $ports; do
        iptables -I INPUT -p tcp -d "$ip_addr" --dport "$port" -j ACCEPT
    done
    save_iptables_rules
    echo -e "${gl_lv}已开放容器 $docker_name 的所有端口${gl_bai}"
}

close_container_ports() {
    read -e -p "请输入容器名: " docker_name
    if ! docker ps -a --format '{{.Names}}' | grep -wq "$docker_name"; then
        echo -e "${gl_hong}容器不存在${gl_bai}"
        return
    fi
    ports=$(docker port "$docker_name" | awk -F'[:]' '{print $NF}' | uniq)
    ip_addr=$(hostname -I | awk '{print $1}')
    for port in $ports; do
        iptables -D INPUT -p tcp -d "$ip_addr" --dport "$port" -j ACCEPT 2>/dev/null
    done
    save_iptables_rules
    echo -e "${gl_lv}已关闭容器 $docker_name 的端口访问${gl_bai}"
}

open_all_containers_ports() {
    containers=$(docker ps -a --format '{{.Names}}')
    if [ -z "$containers" ]; then
        echo -e "${gl_hong}没有找到任何容器${gl_bai}"
        return
    fi
    ip_addr=$(hostname -I | awk '{print $1}')
    for docker_name in $containers; do
        ports=$(docker port "$docker_name" | awk -F'[:]' '{print $NF}' | uniq)
        if [ -z "$ports" ]; then
            echo -e "${gl_huang}容器 $docker_name 未映射端口，跳过${gl_bai}"
            continue
        fi
        for port in $ports; do
            iptables -I INPUT -p tcp -d "$ip_addr" --dport "$port" -j ACCEPT
        done
        echo -e "${gl_lv}已开放容器 $docker_name 的端口: $ports${gl_bai}"
    done
    save_iptables_rules
    echo -e "${gl_lv}所有容器端口已开放并已保存${gl_bai}"
}

# ---------------- 容器管理 ----------------
docker_ps() {
    while true; do
        clear
        echo "===== Docker 容器管理 ====="
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo "1. 创建容器  2. 启动容器  3. 停止容器  4. 删除容器  5. 重启容器"
        echo "6. 启动所有  7. 停止所有  8. 删除所有  9. 重启所有"
        echo "11. 进入容器  12. 容器日志  13. 容器网络  14. 容器占用"
        echo "15. 开放容器端口访问  16. 关闭容器端口访问  17. 一键开放所有容器端口"
        echo "0. 返回"
        read -e -p "选择: " sub_choice
        case $sub_choice in
            1) read -e -p "请输入 Docker 命令: " cmd; $cmd ;;
            2) read -e -p "容器名: " name; docker start $name ;;
            3) read -e -p "容器名: " name; docker stop $name ;;
            4) read -e -p "容器名: " name; docker rm -f $name ;;
            5) read -e -p "容器名: " name; docker restart $name ;;
            6) docker start $(docker ps -a -q) ;;
            7) docker stop $(docker ps -q) ;;
            8) read -e -p "确认删除所有容器(Y/N): " yn; [[ $yn =~ [Yy] ]] && docker rm -f $(docker ps -a -q) ;;
            9) docker restart $(docker ps -q) ;;
            11) read -e -p "容器名: " name; docker exec -it $name /bin/bash ;;
            12) read -e -p "容器名: " name; docker logs $name ;;
            13)
                for cid in $(docker ps -q); do
                    docker inspect --format '{{.Name}} - {{range $k,$v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{end}}' $cid
                done ;;
            14) docker stats --no-stream ;;
            15) open_container_ports ;;
            16) close_container_ports ;;
            17) open_all_containers_ports ;;
            0) break ;;
        esac
        read -p "回车继续..."
    done
}

# ---------------- 镜像管理 ----------------
docker_image() {
    while true; do
        clear
        echo "===== Docker 镜像管理 ====="
        docker images
        echo "1. 拉取  2. 更新  3. 删除  4. 删除所有"
        echo "0. 返回"
        read -e -p "选择: " sub_choice
        case $sub_choice in
            1) read -e -p "镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            2) read -e -p "镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            3) read -e -p "镜像名: " imgs; for img in $imgs; do docker rmi -f $img; done ;;
            4) read -e -p "确认删除所有镜像(Y/N): " yn; [[ $yn =~ [Yy] ]] && docker rmi -f $(docker images -q) ;;
            0) break ;;
        esac
        read -p "回车继续..."
    done
}

# ---------------- 主菜单 ----------------
main_menu() {
    root_use
    check_crontab_installed
    while true; do
        clear
        echo "===== Docker 一键管理脚本 ====="
        echo "1. 安装 Docker"
        echo "2. 卸载 Docker"
        echo "3. Docker 容器管理"
        echo "4. Docker 镜像管理"
        echo "5. 开启 IPv6"
        echo "6. 关闭 IPv6"
        echo "0. 退出"
        read -e -p "选择: " choice
        case $choice in
            1) docker_official_install ;;
            2) docker_uninstall ;;
            3) docker_ps ;;
            4) docker_image ;;
            5) docker_ipv6_on ;;
            6) docker_ipv6_off ;;
            0) exit ;;
        esac
    done
}

main_menu
