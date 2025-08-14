#!/bin/bash
# ========================================
# Wallos 一键部署脚本
# 适用环境：Linux + Docker 已安装
# 作者：Linai Li 专用版
# ========================================

# 设置变量
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

# 创建目录
mkdir -p "$DATA_DIR" "$LOGO_DIR"

# 检查容器是否已存在
if docker ps -a --format '{{.Names}}' | grep -w "$APP_NAME" &> /dev/null; then
    echo "⚠️ 检测到已有容器 [$APP_NAME]，正在删除..."
    docker stop "$APP_NAME" &> /dev/null
    docker rm "$APP_NAME" &> /dev/null
fi

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

# 检查运行状态
if [ $? -eq 0 ]; then
    echo "✅ Wallos 部署完成！"
    echo "访问地址：http://$(curl -s ifconfig.me):${APP_PORT}"
    echo "数据目录：$DATA_DIR"
    echo "Logo 目录：$LOGO_DIR"
else
    echo "❌ Wallos 部署失败，请检查 Docker 配置。"
fi
