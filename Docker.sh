#!/bin/bash
# ========================================
# 一键 Docker 安装 & 容器管理脚本
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

install() {
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

# ---------------- Docker 安装 ----------------
install_add_docker_cn() {
    local country=$(curl -s ipinfo.io/country)
    if [ "$country" = "CN" ]; then
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
    fi
    systemctl_enable_start
}

install_add_docker_guanfang() {
    local country=$(curl -s ipinfo.io/country)
    if [ "$country" = "CN" ]; then
        cd ~
        curl -sS -O https://raw.githubusercontent.com/kejilion/docker/main/install && chmod +x install
        sh install --mirror Aliyun
        rm -f install
    else
        curl -fsSL https://get.docker.com | sh
    fi
    install_add_docker_cn
}

install_add_docker() {
    echo -e "${gl_huang}正在安装 Docker 环境...${gl_bai}"
    if [ -f /etc/os-release ] && grep -q "Fedora" /etc/os-release; then
        install_add_docker_guanfang
    elif command -v dnf &>/dev/null; then
        dnf update -y
        dnf install -y yum-utils device-mapper-persistent-data lvm2
        rm -f /etc/yum.repos.d/docker*.repo > /dev/null
        local country=$(curl -s ipinfo.io/country)
        local arch=$(uname -m)
        if [ "$country" = "CN" ]; then
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo | tee /etc/yum.repos.d/docker-ce.repo > /dev/null
        else
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null
        fi
        dnf install -y docker-ce docker-ce-cli containerd.io
        install_add_docker_cn
    elif [ -f /etc/os-release ] && grep -q "Kali" /etc/os-release; then
        apt update
        apt upgrade -y
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        install_add_docker_cn
    else
        install_add_docker_guanfang
    fi
    sleep 2
}

install_docker() {
    if ! command -v docker &>/dev/null; then
        install_add_docker
    fi
}

# ---------------- crontab ----------------
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
    install jq
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
    install jq
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
        echo -e "${gl_huang}已成功关闭 IPv6${gl_bai}"
    fi
}

# ---------------- 容器与镜像管理 ----------------
docker_ps() {
    while true; do
        clear
        echo "===== Docker 容器管理 ====="
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo "1. 创建容器  2. 启动容器  3. 停止容器  4. 删除容器  5. 重启容器"
        echo "6. 启动所有  7. 停止所有  8. 删除所有  9. 重启所有"
        echo "11. 进入容器  12. 容器日志  13. 容器网络  14. 容器占用"
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
                echo "容器网络信息:"
                for cid in $(docker ps -q); do
                    docker inspect --format '{{.Name}} - {{range $k,$v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{end}}' $cid
                done
                ;;
            14) docker stats --no-stream ;;
            0) break ;;
        esac
        read -p "回车继续..."
    done
}

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
    install_docker
    check_crontab_installed
    while true; do
        clear
        echo "===== Docker 一键管理脚本 ====="
        echo "1. 容器管理"
        echo "2. 镜像管理"
        echo "3. 开启 IPv6"
        echo "4. 关闭 IPv6"
        echo "0. 退出"
        read -e -p "选择: " choice
        case $choice in
            1) docker_ps ;;
            2) docker_image ;;
            3) docker_ipv6_on ;;
            4) docker_ipv6_off ;;
            0) exit 0 ;;
        esac
    done
}

main_menu
