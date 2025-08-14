#!/bin/bash
# ========================================
# OCI Helper 修改账号密码脚本
# 适用环境：已部署 OCI Helper (docker-compose)
# ========================================

CONFIG_FILE="/app/oci-helper/application.yml"
CONTAINER_NAME="oci-helper"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "\033[31m[错误]\033[0m 配置文件 $CONFIG_FILE 未找到，请确认OCI Helper已安装并挂载该路径。"
    exit 1
fi

# 输入新账号
read -p "请输入新的账号: " NEW_USER
# 输入新密码（隐藏输入）
read -sp "请输入新的密码: " NEW_PASS
echo

# 修改配置文件
sed -i "s/^username:.*/username: $NEW_USER/" "$CONFIG_FILE"
sed -i "s/^password:.*/password: $NEW_PASS/" "$CONFIG_FILE"

echo -e "\033[32m[成功]\033[0m 已更新账号密码，正在重启容器..."

# 重启容器
docker restart "$CONTAINER_NAME"

if [ $? -eq 0 ]; then
    echo -e "\033[32m[完成]\033[0m 容器已重启，请使用新账号密码登录。"
else
    echo -e "\033[31m[失败]\033[0m 容器重启失败，请手动检查。"
fi
