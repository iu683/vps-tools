#!/bin/bash
# Debian/Ubuntu 一键更新脚本

echo -e "\n=== 开始更新系统 ===\n"

# 更新软件源
sudo apt update

# 升级软件包
sudo apt -y upgrade
sudo apt -y full-upgrade

# 清理无用的依赖和缓存
sudo apt -y autoremove
sudo apt -y autoclean

echo -e "\n=== 系统已完成更新和清理！ ===\n"
