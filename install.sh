#!/bin/bash

# 你的 GitHub 直链（替换成自己的仓库地址）
GITHUB_URL="https://raw.githubusercontent.com/iu683/vps-tools/main/vps-tools.sh"

# 安装快捷启动 m
if [[ ! -f /usr/local/bin/m ]]; then
    echo "注册快捷启动命令 m..."
    echo "bash <(curl -fsSL $GITHUB_URL)" > /usr/local/bin/m
    chmod +x /usr/local/bin/m
    echo "安装完成！直接输入 m 即可运行工具箱"
else
    echo "m 已存在，跳过安装"
fi

