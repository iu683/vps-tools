#!/bin/bash
# ========================================
# STB 本地源码一键运行脚本（带 MongoDB 安装）
# 作者: Linai Li
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

REPO_URL="https://github.com/setube/stb.git"
APP_DIR="stb"
MONGO_HOST=${MONGO_URL:-"mongodb://localhost:27017/stb"}

# ================== 菜单 ==================
function show_menu() {
    echo -e "${CYAN}================= STB 本地运行管理 =================${RESET}"
    echo -e "${GREEN}1.${RESET} 下载源码"
    echo -e "${GREEN}2.${RESET} 安装依赖"
    echo -e "${GREEN}3.${RESET} 编译项目"
    echo -e "${GREEN}4.${RESET} 启动项目"
    echo -e "${GREEN}5.${RESET} 查看日志"
    echo -e "${GREEN}6.${RESET} 停止项目"
    echo -e "${GREEN}7.${RESET} 检测 MongoDB"
    echo -e "${GREEN}8.${RESET} 安装 MongoDB (本地或 Docker)"
    echo -e "${GREEN}0.${RESET} 退出"
    echo -e "${CYAN}================================================${RESET}"
}

# ================== 功能 ==================
function clone_repo() {
    if [ -d "$APP_DIR" ]; then
        echo -e "${YELLOW}目录 $APP_DIR 已存在，跳过克隆${RESET}"
    else
        echo -e "${GREEN}正在克隆源码...${RESET}"
        git clone $REPO_URL
    fi
}

function install_dependencies() {
    echo -e "${GREEN}安装 pnpm...${RESET}"
    npm install -g pnpm
    echo -e "${GREEN}安装项目依赖...${RESET}"
    cd $APP_DIR || exit
    pnpm install
    cd ..
}

function build_project() {
    echo -e "${GREEN}编译项目...${RESET}"
    cd $APP_DIR || exit
    pnpm build
    cd ..
}

function check_mongo() {
    echo -e "${YELLOW}检测 MongoDB 服务...${RESET}"
    HOST=$(echo $MONGO_HOST | sed -E 's/mongodb:\/\/([^:/]+).*/\1/')
    PORT=$(echo $MONGO_HOST | sed -E 's/.*:([0-9]+).*/\1/')
    nc -z -w 3 $HOST $PORT
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}MongoDB 可用: $MONGO_HOST${RESET}"
        return 0
    else
        echo -e "${RED}无法连接 MongoDB: $MONGO_HOST${RESET}"
        return 1
    fi
}

function start_project() {
    check_mongo || { echo -e "${RED}请先确保 MongoDB 可用${RESET}"; return; }
    echo -e "${GREEN}启动项目...${RESET}"
    cd $APP_DIR || exit
    export MONGO_URL=$MONGO_HOST
    nohup pnpm start > app.log 2>&1 &
    cd ..
    echo -e "${YELLOW}项目已启动，日志输出到 $APP_DIR/app.log${RESET}"
}

function view_logs() {
    if [ -f "$APP_DIR/app.log" ]; then
        tail -f $APP_DIR/app.log
    else
        echo -e "${RED}日志文件不存在，请先启动项目${RESET}"
    fi
}

function stop_project() {
    echo -e "${YELLOW}停止项目...${RESET}"
    PID=$(pgrep -f "pnpm start")
    if [ "$PID" ]; then
        kill -9 $PID
        echo -e "${GREEN}项目已停止${RESET}"
    else
        echo -e "${RED}项目未运行${RESET}"
    fi
}

function install_mongo() {
    echo -e "${YELLOW}请选择安装方式:${RESET}"
    echo "1) 本地系统安装 MongoDB (适用于 Debian/Ubuntu)"
    echo "2) 使用 Docker 安装 MongoDB"
    read -p "请输入选项 [1-2]: " opt

    case $opt in
        1)
            echo -e "${GREEN}开始本地安装 MongoDB...${RESET}"
            sudo apt update
            sudo apt install -y mongodb
            sudo systemctl enable mongodb
            sudo systemctl start mongodb
            echo -e "${GREEN}MongoDB 已启动${RESET}"
            ;;
        2)
            echo -e "${GREEN}使用 Docker 安装 MongoDB...${RESET}"
            docker pull mongo:6
            docker run -d --name stb-mongo -p 27017:27017 mongo:6
            echo -e "${GREEN}MongoDB Docker 容器已启动，端口 27017${RESET}"
            ;;
        *)
            echo -e "${RED}无效选项${RESET}"
            ;;
    esac
}

# ================== 主循环 ==================
while true; do
    show_menu
    read -p "请输入选项: " choice
    case $choice in
        1) clone_repo ;;
        2) install_dependencies ;;
        3) build_project ;;
        4) start_project ;;
        5) view_logs ;;
        6) stop_project ;;
        7) check_mongo ;;
        8) install_mongo ;;
        0) echo -e "${GREEN}退出脚本${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入${RESET}" ;;
    esac
done
