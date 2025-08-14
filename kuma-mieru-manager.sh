
#!/bin/bash

# ================================
# kuma-mieru 管理脚本（菜单式）
# ================================

# 颜色输出
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
plain="\033[0m"

# 项目目录
APP_DIR="$HOME/kuma-mieru"

# 检查 root
if [ "$(id -u)" != "0" ]; then
    echo -e "${red}请使用 root 用户运行脚本${plain}"
    exit 1
fi

# 安装 Docker / Compose
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${yellow}安装 Docker...${plain}"
        apt update
        apt install -y docker.io
    fi
    if ! docker compose version &> /dev/null; then
        echo -e "${yellow}安装 Docker Compose 插件...${plain}"
        apt install -y docker-compose-plugin
    fi
}

# 部署安装
install_app() {
    install_docker

    echo -e "${yellow}请输入 Uptime Kuma 地址:${plain}"
    read UPTIME_KUMA_BASE_URL
    echo -e "${yellow}请输入页面 ID:${plain}"
    read PAGE_ID

    # 克隆或更新仓库
    if [ -d "$APP_DIR" ]; then
        echo -e "${yellow}检测到已有项目，拉取最新代码...${plain}"
        cd "$APP_DIR"
        git pull
    else
        git clone https://github.com/Alice39s/kuma-mieru.git "$APP_DIR"
        cd "$APP_DIR"
    fi

    # 配置 .env
    cp -f .env.example .env
    sed -i "s|^UPTIME_KUMA_BASE_URL=.*|UPTIME_KUMA_BASE_URL=${UPTIME_KUMA_BASE_URL}|" .env
    sed -i "s|^PAGE_ID=.*|PAGE_ID=${PAGE_ID}|" .env

    # 启动服务
    docker compose up -d
    echo -e "${green}部署完成！访问地址：${UPTIME_KUMA_BASE_URL}${plain}"
}

# 更新服务
update_app() {
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${red}项目未安装，请先安装！${plain}"
        return
    fi
    cd "$APP_DIR"
    echo -e "${yellow}拉取最新代码并重启服务...${plain}"
    git pull
    docker compose pull
    docker compose up -d
    echo -e "${green}更新完成！${plain}"
}

# 卸载服务
uninstall_app() {
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${red}项目未安装，无需卸载${plain}"
        return
    fi
    cd "$APP_DIR"
    echo -e "${yellow}停止并删除容器和镜像...${plain}"
    docker compose down --rmi all
    cd ~
    rm -rf "$APP_DIR"
    echo -e "${green}卸载完成！${plain}"
}

# 菜单
while true; do
    echo -e "\n${green}=== kuma-mieru 管理菜单 ===${plain}"
    echo "1) 安装 / 部署"
    echo "2) 更新"
    echo "3) 卸载"
    echo "0) 退出"
    echo -ne "请选择操作: "
    read choice
    case "$choice" in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项${plain}" ;;
    esac
done
