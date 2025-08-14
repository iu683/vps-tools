#!/bin/bash
# ========================================
# Vertex 一键管理脚本（完整增强版）
# 支持自动检测更新 & 查看初始密码
# 作者：Linai Li
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# 配置
APP_NAME="vertex"
APP_PORT=3000
DATA_DIR="/root/vertex"
IMAGE_NAME="lswl/vertex:stable"
TIMEZONE="Asia/Shanghai"

# 检查 Docker
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}错误: 未检测到 Docker，请先安装！${RESET}"
        exit 1
    fi
}

# 获取远程镜像 Digest
get_remote_digest() {
    curl -s "https://hub.docker.com/v2/repositories/${IMAGE_NAME%%:*}/tags/${IMAGE_NAME##*:}" \
    | grep -o '"digest": *"[^"]*' | head -n1 | awk -F '"' '{print $4}'
}

# 获取本地镜像 Digest
get_local_digest() {
    docker inspect --format='{{index .RepoDigests 0}}' "${IMAGE_NAME}" 2>/dev/null | awk -F '@' '{print $2}'
}

# 检查更新
check_update() {
    echo -e "${YELLOW}正在检测镜像版本...${RESET}"
    remote_digest=$(get_remote_digest)
    local_digest=$(get_local_digest)
    if [ -z "$local_digest" ]; then
        echo -e "${RED}本地未安装 ${IMAGE_NAME}${RESET}"
        return
    fi
    if [ "$remote_digest" != "$local_digest" ]; then
        echo -e "${YELLOW}发现新版本镜像，建议更新！${RESET}"
    else
        echo -e "${GREEN}当前已是最新版本${RESET}"
    fi
}

# 部署 Vertex
install_vertex() {
    check_docker
    mkdir -p "${DATA_DIR}"
    echo -e "${YELLOW}拉取镜像：${IMAGE_NAME}${RESET}"
    docker pull "${IMAGE_NAME}"
    if docker ps -a --format '{{.Names}}' | grep -q "^${APP_NAME}$"; then
        echo -e "${YELLOW}已有容器 ${APP_NAME}，正在删除...${RESET}"
        docker stop "${APP_NAME}" && docker rm "${APP_NAME}"
    fi
    echo -e "${YELLOW}正在启动 Vertex...${RESET}"
    docker run -d \
      --name "${APP_NAME}" \
      -v "${DATA_DIR}:/vertex" \
      -p ${APP_PORT}:3000 \
      -e TZ=${TIMEZONE} \
      --restart unless-stopped \
      "${IMAGE_NAME}"
    echo -e "${GREEN}Vertex 部署完成！${RESET}"
    echo -e "${CYAN}访问地址：http://$(hostname -I | awk '{print $1}'):${APP_PORT}${RESET}"
}

# 启动
start_vertex() { docker start "${APP_NAME}" && echo -e "${GREEN}已启动 Vertex${RESET}"; }

# 停止
stop_vertex() { docker stop "${APP_NAME}" && echo -e "${YELLOW}已停止 Vertex${RESET}"; }

# 重启
restart_vertex() { docker restart "${APP_NAME}" && echo -e "${GREEN}已重启 Vertex${RESET}"; }

# 日志
logs_vertex() { docker logs -f "${APP_NAME}"; }

# 更新
update_vertex() {
    echo -e "${YELLOW}正在更新 Vertex...${RESET}"
    docker pull "${IMAGE_NAME}"
    docker stop "${APP_NAME}" && docker rm "${APP_NAME}"
    install_vertex
}

# 卸载
uninstall_vertex() {
    docker stop "${APP_NAME}" && docker rm "${APP_NAME}"
    echo -e "${YELLOW}是否删除数据目录 ${DATA_DIR}？[y/N]${RESET}"
    read -r del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm -rf "${DATA_DIR}"
        echo -e "${RED}已删除数据目录${RESET}"
    fi
    echo -e "${GREEN}Vertex 已卸载${RESET}"
}

# 查看初始密码
show_password() {
    PASS_FILE="${DATA_DIR}/password"
    if [ -f "$PASS_FILE" ]; then
        echo -e "${CYAN}Vertex 默认用户名: admin${RESET}"
        echo -e "${YELLOW}初始密码: $(cat "$PASS_FILE")${RESET}"
        echo -e "${RED}⚠️  请复制密码并在登录后尽快修改账号和密码！${RESET}"
    else
        echo -e "${RED}未找到密码文件，请先部署 Vertex 或检查 ${PASS_FILE}${RESET}"
    fi
}

# 菜单
menu() {
    clear
    echo -e "${CYAN}==== Vertex 管理菜单 ====${RESET}"
    check_update
    echo -e "1. 部署 Vertex"
    echo -e "2. 启动 Vertex"
    echo -e "3. 停止 Vertex"
    echo -e "4. 重启 Vertex"
    echo -e "5. 查看日志"
    echo -e "6. 更新 Vertex"
    echo -e "7. 卸载 Vertex"
    echo -e "8. 查看初始密码"
    echo -e "0. 退出"
    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read -r choice
    case "$choice" in
        1) install_vertex ;;
        2) start_vertex ;;
        3) stop_vertex ;;
        4) restart_vertex ;;
        5) logs_vertex ;;
        6) update_vertex ;;
        7) uninstall_vertex ;;
        8) show_password ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
}

# 循环菜单
while true; do
    menu
    echo -e "${YELLOW}按回车键继续...${RESET}"
    read -r
done
