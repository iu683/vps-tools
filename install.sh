#!/bin/bash

# 工具箱脚本 URL（请替换为你的脚本地址）
TOOLBOX_URL="https://raw.githubusercontent.com/iu683/vps-tools/main/vps-tools.sh"

INSTALL_PATH="$HOME/vps-toolbox.sh"

echo "开始下载安装脚本到 $INSTALL_PATH ..."
curl -fsSL "$TOOLBOX_URL" -o "$INSTALL_PATH"

if [[ $? -ne 0 ]]; then
  echo "下载失败，请检查网络和URL是否正确！"
  exit 1
fi

chmod +x "$INSTALL_PATH"
echo "脚本下载完成，设置为可执行。"

create_shortcut() {
  local shortcut_path="/usr/local/bin/$1"
  echo "创建快捷指令 $1 ..."
  sudo bash -c "cat > $shortcut_path <<EOF
#!/bin/bash
bash \"$INSTALL_PATH\" \"\$@\"
EOF"
  sudo chmod +x "$shortcut_path"
  echo "快捷指令 $1 创建完成。"
}

create_shortcut "m"
create_shortcut "M"

echo -e "\n安装完成！你可以输入 m 或 M 运行工具箱。\n"
