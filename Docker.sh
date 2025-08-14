#!/bin/bash
# VPS Docker 完整管理脚本（含 IPv6、端口管理、iptables 自动保存、镜像管理）

# ================== 颜色 ==================
gl_huang="\033[33m"
gl_lv="\033[32m"
gl_hong="\033[31m"
gl_bai="\033[0m"

# ================== 工具函数 ==================
root_use() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${gl_hong}请使用 root 用户运行脚本${gl_bai}"
        exit 1
    fi
}

sync_system_time() {
    if command -v ntpdate &>/dev/null; then
        ntpdate time.windows.com >/dev/null 2>&1
    fi
}

systemctl_enable_start() {
    if command -v systemctl &>/dev/null; then
        systemctl enable docker >/dev/null 2>&1
        systemctl restart docker >/dev/null 2>&1
    else
        service docker restart >/dev/null 2>&1
    fi
}

docker_cleanup() {
    if command -v docker &>/dev/null; then
        echo -e "${gl_lv}检测到已安装 Docker，卸载旧版本...${gl_bai}"
        apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine containerd.io 2>/dev/null || true
    fi
}

install_jq() {
    command -v jq &>/dev/null || {
        if command -v apt &>/dev/null; then
            apt update && apt install -y jq
        elif command -v yum &>/dev/null; then
            yum install -y jq
        fi
    }
}

# ================== Docker 安装/更新 ==================
docker_official_install() {
    root_use
    docker_cleanup
    sync_system_time
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

    if [ "$(docker ps -a -q | wc -l)" -gt 0 ]; then
        echo -e "${gl_lv}正在启动已有容器...${gl_bai}"
        docker start $(docker ps -a -q)
    fi

    echo -e "${gl_lv}Docker 安装完成并启动所有容器${gl_bai}"
}

docker_update() {
    root_use
    echo -e "${gl_huang}正在更新 Docker...${gl_bai}"
    sync_system_time
    curl -fsSL https://get.docker.com | sh

    local country=$(curl -s ipinfo.io/country)
    if [ "$country" = "CN" ]; then
        echo -e "${gl_lv}检测到中国大陆，重新配置国内加速源${gl_bai}"
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
    fi

    systemctl_enable_start

    if [ "$(docker ps -a -q | wc -l)" -gt 0 ]; then
        echo -e "${gl_lv}正在启动已有容器...${gl_bai}"
        docker start $(docker ps -a -q)
    fi

    echo -e "${gl_lv}Docker 更新完成并启动所有容器${gl_bai}"
}

docker_uninstall() {
    root_use
    echo -e "${gl_hong}卸载 Docker...${gl_bai}"
    systemctl stop docker >/dev/null 2>&1
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine containerd.io 2>/dev/null || true
    rm -rf /etc/docker /var/lib/docker /var/lib/containerd
    echo -e "${gl_lv}Docker 卸载完成${gl_bai}"
}

# ================== Docker IPv6 ==================
docker_ipv6_on() {
    root_use
    install_jq
    local CONFIG_FILE="/etc/docker/daemon.json"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}' | jq . > "$CONFIG_FILE"
    else
        ORIGINAL=$(<"$CONFIG_FILE")
        UPDATED=$(echo "$ORIGINAL" | jq '. + {ipv6:true,"fixed-cidr-v6":"2001:db8:1::/64"}')
        echo "$UPDATED" | jq . > "$CONFIG_FILE"
    fi
    systemctl_enable_start
    echo -e "${gl_lv}IPv6 已开启${gl_bai}"
}

docker_ipv6_off() {
    root_use
    install_jq
    local CONFIG_FILE="/etc/docker/daemon.json"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${gl_hong}配置文件不存在${gl_bai}"
        return
    fi
    ORIGINAL=$(<"$CONFIG_FILE")
    UPDATED=$(echo "$ORIGINAL" | jq 'del(.["fixed-cidr-v6"]) | .ipv6=false')
    echo "$UPDATED" | jq . > "$CONFIG_FILE"
    systemctl_enable_start
    echo -e "${gl_lv}IPv6 已关闭${gl_bai}"
}

# ================== Docker 镜像管理 ==================
docker_image_manage() {
while true; do
    clear
    echo "Docker 镜像列表"
    docker image ls
    echo ""
    echo "镜像操作"
    echo "------------------------"
    echo "1. 获取指定镜像"
    echo "2. 更新指定镜像"
    echo "3. 删除指定镜像"
    echo "4. 删除所有镜像"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -e -p "请输入你的选择: " sub_choice
    case $sub_choice in
        1)
            read -e -p "请输入镜像名（可多个空格分隔）: " imagenames
            for name in $imagenames; do
                echo -e "${gl_huang}正在获取镜像: $name${gl_bai}"
                docker pull $name
            done
            ;;
        2)
            read -e -p "请输入镜像名（可多个空格分隔）: " imagenames
            for name in $imagenames; do
                echo -e "${gl_huang}正在更新镜像: $name${gl_bai}"
                docker pull $name
            done
            ;;
        3)
            read -e -p "请输入镜像名（可多个空格分隔）: " imagenames
            for name in $imagenames; do
                docker rmi -f $name
            done
            ;;
        4)
            read -e -p "确定删除所有镜像吗？(Y/N): " choice
            [[ "$choice" =~ [Yy] ]] && docker rmi -f $(docker images -q)
            ;;
        0) break ;;
        *) echo "无效选项" ;;
    esac
done
}

# ================== Docker 容器管理 ==================
docker_ps() {
while true; do
    clear
    echo "Docker容器列表"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "容器操作"
    echo "------------------------"
    echo "1. 创建新的容器"
    echo "2. 启动指定容器             6. 启动所有容器"
    echo "3. 停止指定容器             7. 停止所有容器"
    echo "4. 删除指定容器             8. 删除所有容器"
    echo "5. 重启指定容器             9. 重启所有容器"
    echo "------------------------"
    echo "11. 进入指定容器           12. 查看容器日志"
    echo "13. 查看容器网络           14. 查看容器占用"
    echo "15. 开放所有端口           16. 阻止容器端口访问"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -e -p "请输入你的选择: " sub_choice
    case $sub_choice in
        1) read -e -p "请输入创建命令: " dockername; $dockername ;;
        2) read -e -p "请输入容器名（多个空格分隔）: " dockername; docker start $dockername ;;
        3) read -e -p "请输入容器名（多个空格分隔）: " dockername; docker stop $dockername ;;
        4) read -e -p "请输入容器名（多个空格分隔）: " dockername; docker rm -f $dockername ;;
        5) read -e -p "请输入容器名（多个空格分隔）: " dockername; docker restart $dockername ;;
        6) docker start $(docker ps -a -q) ;;
        7) docker stop $(docker ps -q) ;;
        8) read -e -p "确定删除所有容器吗？(Y/N): " choice; [[ "$choice" =~ [Yy] ]] && docker rm -f $(docker ps -a -q) ;;
        9) docker restart $(docker ps -q) ;;
        11) read -e -p "请输入容器名: " dockername; docker exec -it $dockername /bin/sh ;;
        12) read -e -p "请输入容器名: " dockername; docker logs $dockername ;;
        13)
            echo "------------------------------------------------------------"
            printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"
            for id in $(docker ps -q); do
                info=$(docker inspect --format '{{ .Name }}{{ range $n, $conf := .NetworkSettings.Networks }} {{ $n }} {{ $conf.IPAddress }}{{ end }}' $id)
                name=$(echo $info | awk '{print $1}')
                nets=$(echo $info | cut -d' ' -f2-)
                while read -r line; do
                    net=$(echo $line | awk '{print $1}')
                    ip=$(echo $line | awk '{print $2}')
                    printf "%-20s %-20s %-15s\n" "$name" "$net" "$ip"
                done <<< "$nets"
            done
            ;;
        14) docker stats --no-stream ;;
        15)
            read -e -p "请输入容器名: " docker_name
            ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $docker_name)
            iptables -I INPUT -p tcp -d $ip -j ACCEPT
            iptables -I INPUT -p udp -d $ip -j ACCEPT
            iptables-save >/etc/iptables/rules.v4 2>/dev/null || iptables-save >/etc/iptables.rules
            echo -e "${gl_lv}已开放所有端口并保存iptables规则${gl_bai}"
            ;;
        16)
            read -e -p "请输入容器名: " docker_name
            ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $docker_name)
            iptables -D INPUT -p tcp -d $ip -j ACCEPT
            iptables -D INPUT -p udp -d $ip -j ACCEPT
            iptables-save >/etc/iptables/rules.v4 2>/dev/null || iptables-save >/etc/iptables.rules
            echo -e "${gl_lv}已阻止容器端口并保存iptables规则${gl_bai}"
            ;;
        *) break ;;
    esac
done
}

# ================== 主菜单 ==================
while true; do
    clear
    echo "===== Docker 管理脚本 ====="
    echo "1. 安装 Docker"
    echo "2. 更新 Docker"
    echo "3. 卸载 Docker"
    echo "4. 管理容器"
    echo "5. 管理镜像"
    echo "6. 开启 Docker IPv6"
    echo "7. 关闭 Docker IPv6"
    echo "0. 退出"
    read -e -p "请选择: " choice
    case $choice in
        1) docker_official_install ;;
        2) docker_update ;;
        3) docker_uninstall ;;
        4) docker_ps ;;
        5) docker_image_manage ;;
        6) docker_ipv6_on ;;
        7) docker_ipv6_off ;;
        0) exit ;;
        *) echo "无效选项" ;;
    esac
done
