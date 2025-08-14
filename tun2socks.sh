#!/bin/bash
set -e

#========================
# 颜色定义
#========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

#========================
# 工具函数
#========================
info()    { echo -e "${BLUE}[信息]${NC} $1"; }
success() { echo -e "${GREEN}[成功]${NC} $1"; }
warning() { echo -e "${YELLOW}[警告]${NC} $1"; }
error()   { echo -e "${RED}[错误]${NC} $1"; }

require_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 权限运行。"
        exit 1
    fi
}

pause() { read -rp "按回车继续..."; }

#========================
# Alice 端口选择
#========================
select_alice_port() {
    local options=(
        "新加坡机房IP:10001"
        "台湾家宽:30000"
        "日本家宽:50000"
    )
    echo -e "${YELLOW}请选择 Alice 模式 Socks5 出口端口:${NC}"
    for i in "${!options[@]}"; do
        local name="${options[$i]%%:*}"
        local port="${options[$i]#*:}"
        echo " $((i+1))) $name (端口: $port)"
    done
    while true; do
        read -rp "请输入选项 (1-${#options[@]}，默认1): " choice
        choice=${choice:-1}
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local port="${options[$((choice-1))]#*:}"
            echo "$port"
            return
        else
            error "无效选择"
        fi
    done
}

#========================
# Custom 节点输入
#========================
get_custom_server_config() {
    read -rp "请输入Socks5服务器地址 (IPv4/IPv6): " address
    read -rp "请输入Socks5端口: " port
    read -rp "请输入用户名 (可选): " username
    if [ -n "$username" ]; then
        read -rp "请输入密码 (可选): " password
    else
        password=""
    fi
    echo "$address;$port;$username;$password"
}

#========================
# 安装函数
#========================
install_tun2socks() {
    cleanup_ip_rules

    local MODE=$1
    local CONFIG_DIR="/etc/tun2socks"
    local CONFIG_FILE="$CONFIG_DIR/config.yaml"
    local BINARY="/usr/local/bin/tun2socks"

    # 下载二进制文件
    info "下载最新 tun2socks 二进制..."
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/heiher/hev-socks5-tunnel/releases/latest \
        | grep "browser_download_url" | grep "linux-x86_64" | cut -d '"' -f4)
    curl -L -o "$BINARY" "$DOWNLOAD_URL"
    chmod +x "$BINARY"

    mkdir -p "$CONFIG_DIR"

    if [ "$MODE" = "alice" ]; then
        SOCKS_PORT=$(select_alice_port)
        cat > "$CONFIG_FILE" <<EOF
tunnel:
  name: tun0
  mtu: 8500
  multi-queue: true
  ipv4: 198.18.0.1

socks5:
  port: $SOCKS_PORT
  address: '2a14:67c0:116::1'
  udp: 'udp'
  username: 'alice'
  password: 'alicefofo123..OVO'
  mark: 438
EOF
    elif [ "$MODE" = "custom" ]; then
        IFS=";" read -r ADDR PORT USER PASS <<< "$(get_custom_server_config)"
        cat > "$CONFIG_FILE" <<EOF
tunnel:
  name: tun0
  mtu: 8500
  multi-queue: true
  ipv4: 198.18.0.1

socks5:
  port: $PORT
  address: '$ADDR'
  udp: 'udp'
$( [ -n "$USER" ] && echo "  username: '$USER'" )
$( [ -n "$PASS" ] && echo "  password: '$PASS'" )
  mark: 438
EOF
    fi

    # 创建 systemd 服务
    local SERVICE_FILE="/etc/systemd/system/tun2socks.service"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Tun2Socks Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=$BINARY $CONFIG_FILE
ExecStartPost=/bin/sleep 1
ExecStartPost=/sbin/ip rule add fwmark 438 lookup main pref 10
ExecStartPost=/sbin/ip -6 rule add fwmark 438 lookup main pref 10
ExecStartPost=/sbin/ip route add default dev tun0 table 20
ExecStartPost=/sbin/ip rule add lookup 20 pref 20
ExecStartPost=/sbin/ip rule add to 127.0.0.0/8 lookup main pref 16
ExecStartPost=/sbin/ip rule add to 10.0.0.0/8 lookup main pref 16
ExecStartPost=/sbin/ip rule add to 172.16.0.0/12 lookup main pref 16
ExecStartPost=/sbin/ip rule add to 192.168.0.0/16 lookup main pref 16

ExecStop=/sbin/ip rule del fwmark 438 lookup main pref 10
ExecStop=/sbin/ip -6 rule del fwmark 438 lookup main pref 10
ExecStop=/sbin/ip route del default dev tun0 table 20
ExecStop=/sbin/ip rule del lookup 20 pref 20
ExecStop=/sbin/ip rule del to 127.0.0.0/8 lookup main pref 16
ExecStop=/sbin/ip rule del to 10.0.0.0/8 lookup main pref 16
ExecStop=/sbin/ip rule del to 172.16.0.0/12 lookup main pref 16
ExecStop=/sbin/ip rule del to 192.168.0.0/16 lookup main pref 16

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable tun2socks.service
    systemctl start tun2socks.service

    success "安装完成，服务已启动。"
}

#========================
# 卸载函数
#========================
cleanup_ip_rules() {
    info "清理残留 IP 规则..."
    ip rule del fwmark 438 lookup main pref 10 2>/dev/null || true
    ip -6 rule del fwmark 438 lookup main pref 10 2>/dev/null || true
    ip route del default dev tun0 table 20 2>/dev/null || true
    ip rule del lookup 20 pref 20 2>/dev/null || true
}
uninstall_tun2socks() {
    cleanup_ip_rules
    systemctl stop tun2socks.service 2>/dev/null || true
    systemctl disable tun2socks.service 2>/dev/null || true
    rm -f /etc/systemd/system/tun2socks.service
    rm -rf /etc/tun2socks
    rm -f /usr/local/bin/tun2socks
    systemctl daemon-reload
    success "tun2socks 已卸载完成。"
}

#========================
# 切换 Alice 端口
#========================
switch_alice_port() {
    local CONFIG_FILE="/etc/tun2socks/config.yaml"
    if [ ! -f "$CONFIG_FILE" ]; then
        error "配置文件不存在，请先安装 Alice 模式。"
        return
    fi
    current_port=$(grep -oP 'port: \K[0-9]+' "$CONFIG_FILE")
    info "当前端口: $current_port"
    NEW_PORT=$(select_alice_port)
    sed -i "s/port: $current_port/port: $NEW_PORT/" "$CONFIG_FILE"
    systemctl restart tun2socks.service
    success "已切换端口为 $NEW_PORT 并重启服务。"
}

#========================
# 菜单
#========================
show_menu() {
    clear
    echo -e "${PURPLE}========= Tun2Socks 一键管理菜单 =========${NC}"
    echo "1) 安装 tun2socks"
    echo "2) 卸载 tun2socks"
    echo "3) 切换 Alice 端口"
    echo "4) 退出"
    echo -e "${PURPLE}=======================================${NC}"
}

main() {
    require_root
    while true; do
        show_menu
        read -rp "请输入选项 (1-4): " choice
        case $choice in
            1)
                echo "选择安装模式:"
                echo "1) Alice"
                echo "2) Custom"
                read -rp "请输入选项 (1-2): " mode_choice
                case $mode_choice in
                    1) install_tun2socks "alice" ;;
                    2) install_tun2socks "custom" ;;
                    *) error "无效选择" ;;
                esac
                pause
                ;;
            2) uninstall_tun2socks; pause ;;
            3) switch_alice_port; pause ;;
            4) exit 0 ;;
            *) error "无效选项" ;;
        esac
    done
}

main
