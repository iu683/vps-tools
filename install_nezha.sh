#!/bin/bash
# ========================================
# Nezha Agent 国内一键安装脚本
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# --- 用户输入 ---
read -p "请输入哪吒服务端地址（例：data.example.com:8008）: " SERVER
read -p "请输入 agent 密钥(client_secret): " SECRET

# --- 创建目录 ---
echo -e "${GREEN}创建安装目录 /opt/nezha ...${RESET}"
sudo mkdir -p /opt/nezha

# --- 下载 agent ---
echo -e "${GREEN}下载探针 agent ...${RESET}"
cd /opt/nezha
sudo wget -O nezha-agent https://pan.bobqu.cyou/Code/nezha/nezha-agent
sudo chmod +x nezha-agent

# --- 创建 systemd 服务 ---
echo -e "${GREEN}创建 systemd 服务文件 ...${RESET}"
sudo tee /etc/systemd/system/nezha-agent.service > /dev/null <<EOF
[Unit]
Description=Nezha Agent
After=network.target

[Service]
Type=simple
ExecStart=/opt/nezha/nezha-agent
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# --- 创建配置文件 ---
echo -e "${GREEN}创建配置文件 config.yml ...${RESET}"
sudo tee /opt/nezha/config.yml > /dev/null <<EOF
client_secret: $SECRET
server: $SERVER
EOF

# --- 启动服务 ---
echo -e "${GREEN}启动并启用 nezha-agent ...${RESET}"
sudo systemctl daemon-reload
sudo systemctl enable nezha-agent
sudo systemctl restart nezha-agent

# --- 完成 ---
echo -e "${GREEN}安装完成！可以用下面命令查看状态:${RESET}"
echo -e "sudo systemctl status nezha-agent"
