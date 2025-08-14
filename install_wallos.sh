#!/bin/bash
# ========================================
# Wallos 一键部署脚本（安装 / 卸载 / 更新）
# 适用环境：Linux + Docker 已安装
# 作者：Linai Li 专用版
# ========================================

APP_NAME="wallos"
APP_PORT=9800
DATA_DIR="/root/wallos/data"
LOGO_DIR="/root/wallos/logos"
TIMEZONE="Asia/Shanghai"
IMAGE_NAME="bellamy/wallos:latest"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker 再运行此脚本。"
    exit 1
fi

# 用户选择操作
echo "请选择操作："
echo "1) 安装 / 更新 Wallos"
echo "2) 卸载 Wallos"
read -p "输入数字 [1-2]: " ACTION

# 卸载函数
uninstall_wallos() {
    if docker ps -a --format '{{.Names}}' | grep -w "$APP_NAME" &> /dev/null; then
        echo "⚠️ 正在停止并删除容器 [$APP_NAME]..."
        docker stop "$APP_NAME" &> /dev/null
        docker rm "$APP_NAME" &> /dev/null
        echo "✅ 容器已删除"
    else
        echo "⚠️ 未检测到容器 [$APP_NAME]"
    fi

    # 可选删除数据和logo目录
    read -p "是否删除数据目录和 Logo 目录？(y/N): " DELETE_DIR
    if [[ "$DELETE_DIR" =~ ^[Yy]$ ]]; then
        rm -rf "$DATA_DIR" "$LOGO_DIR"
        echo "✅ 数据目录已删除"
    fi
}

# 安装 / 更新函数
install_wallos() {
    mkdir -p "$DATA_DIR" "$LOGO_DIR"

    # 检查容器是否已存在
    if docker ps -a --format '{{.Names}}' | grep -w "$APP_NAME" &> /dev/null; then
        echo "⚠️ 检测到已有容器 [$APP_NAME]，正在删除旧容器..."
        docker stop "$APP_NAME" &> /dev/null
        docker rm "$APP_NAME" &> /dev/null
    fi

    # 拉取最新镜像
    docker pull "$IMAGE_NAME"

    # 启动容器
    echo "🚀 正在部署 Wallos..."
    docker run -d \
        --restart unless-stopped \
        --name "$APP_NAME" \
        -p ${APP_PORT}:80 \
        -v "$DATA_DIR":/var/www/html/db \
        -v "$LOGO_DIR":/var/www/html/images/uploads/logos \
        -e TZ="$TIMEZONE" \
        "$IMAGE_NAME"

    if [ $? -eq 0 ]; then
        echo "✅ Wallos 部署完成！"
        echo "访问地址：http://$(curl -s ifconfig.me):${APP_PORT}"
        echo "数据目录：$DATA_DIR"
        echo "Logo 目录：$LOGO_DIR"
    else
        echo "❌ Wallos 部署失败，请检查 Docker 配置。"
    fi
}

# 根据选择执行
case $ACTION in
    1)
        install_wallos
        ;;
    2)
        uninstall_wallos
        ;;
    *)
        echo "❌ 无效选择，退出"
        exit 1
        ;;
esac
