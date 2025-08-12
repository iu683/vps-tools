#!/bin/bash

# 安装路径
INSTALL_PATH="$HOME/vps-toolbox.sh"
REPO_URL="https://raw.githubusercontent.com/你的GitHub用户名/vps-toolbox/main"

echo "开始安装服务器工具箱..."

# 下载主脚本
curl -fsSL "$REPO_URL/vps-toolbox.sh" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# 创建快捷指令 m 和 M
for cmd in m M; do
    echo "创建快捷指令 $cmd"
    echo "bash $INSTALL_PATH" | sudo tee "/usr/local/bin/$cmd" >/dev/null
    sudo chmod +x "/usr/local/bin/$cmd"
done

echo "安装完成！你可以通过输入 m 或 M 来运行工具箱"
