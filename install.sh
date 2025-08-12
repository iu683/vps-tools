#!/bin/bash

INSTALL_PATH="$HOME/vps-toolbox.sh"
REPO_URL="https://raw.githubusercontent.com/yourusername/vps-toolbox/main"

echo "开始安装服务器工具箱..."

curl -fsSL "$REPO_URL/vps-toolbox.sh" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# 创建快捷指令 m 和 M（软链接）
for cmd in m M; do
    echo "创建快捷指令 $cmd"
    sudo ln -sf "$INSTALL_PATH" "/usr/local/bin/$cmd"
done

echo "安装完成！你可以通过输入 m 或 M 来运行工具箱"

