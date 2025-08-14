#!/bin/bash
# 1Panel 本地应用更新（ghp.ci 加速 + 备份 + 自动重启）

LOCAL_PATH="/opt/1panel/resource/apps/local"
ZIP_URL="https://ghp.ci/https://github.com/okxlin/appstore/archive/refs/heads/localApps.zip"
BACKUP_DIR="/opt/1panel/resource/apps/backup_$(date +%Y%m%d_%H%M%S)"

# 检查目录
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ 未检测到 1Panel 本地应用目录"
    exit 1
fi

# 备份
mkdir -p "$BACKUP_DIR"
cp -rf "$LOCAL_PATH"/* "$BACKUP_DIR"/
echo "📦 已备份到 $BACKUP_DIR"

# 下载
wget -O "$LOCAL_PATH/localApps.zip" "$ZIP_URL"

# 解压
unzip -o -d "$LOCAL_PATH" "$LOCAL_PATH/localApps.zip"

# 覆盖
cp -rf "$LOCAL_PATH/appstore-localApps/apps/"* "$LOCAL_PATH/"

# 清理
rm -rf "$LOCAL_PATH/appstore-localApps" "$LOCAL_PATH/localApps.zip"

# 重启 1Panel
if systemctl list-units --type=service | grep -q "1panel"; then
    systemctl restart 1panel
    echo "✅ 1Panel 已重启"
else
    echo "⚠️ 未检测到 1Panel 服务，请手动重启"
fi

echo "✅ 本地应用更新完成"
