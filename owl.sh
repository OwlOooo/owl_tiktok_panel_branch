#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
COMPOSE_URL='https://raw.githubusercontent.com/OwlOooo/owl_tiktok_panel_branch/main/docker-compose.yml'
ENV_URL='https://raw.githubusercontent.com/OwlOooo/owl_tiktok_panel_branch/main/.env'

OWL_DIR="/owl"

# 创建 /owl 目录并进入
create_and_enter_owl_dir() {
    if [ ! -d "$OWL_DIR" ]; then
        mkdir -p "$OWL_DIR"
    fi
    cd "$OWL_DIR"
}

# 标题函数
StartTitle() {
    echo -e '  \033[0;1;36;96m欢迎使用猫头鹰订阅管理面板一键脚本\033[0m'
}

# 读取 .env 文件
load_env() {
    if [ ! -f "$OWL_DIR/.env" ]; then
        echo -e "${RED}.env 文件不存在，请先下载 .env 文件。${NC}"
        return 1
    fi
    export $(grep -v '^#' "$OWL_DIR/.env" | xargs)
}

# 端口检测函数
check_ports() {
    return 0
}

# 检测 MySQL 端口
check_mysql_port() {
    return 0
}

# .env 文件检查函数
check_env() {
    if grep -q "127.0.0.1" "$OWL_DIR/.env"; then
        echo -e "${RED}检测到 .env 文件中的 MYSQL_HOST 或 DOMAIN 包含 127.0.0.1，请先修改为正确的 IP 地址。默认文件目录：$OWL_DIR${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi
    return 0
}

# 通用函数
manage_service() {
    local action=$1
    local service=$2

    create_and_enter_owl_dir

    case $action in
        start)
            if [ "$(docker inspect -f '{{.State.Running}}' ${service})" == "true" ]; then
                echo -e "${YELLOW}${service} 容器已经启动。${NC}"
                 docker-compose logs --tail 300 -f ${service}
            else
                echo -e "${GREEN}启动 ${service} 容器...${NC}"
                docker-compose start ${service}
                echo -e "${GREEN}${service} 容器已启动。${NC}"
                 docker-compose logs --tail 300 -f ${service}
            fi
            ;;
        stop)
            if [ "$(docker inspect -f '{{.State.Running}}' ${service})" == "false" ]; then
                echo -e "${YELLOW}${service} 容器已经停止。${NC}"
            else
                echo -e "${GREEN}停止 ${service} 容器...${NC}"
                docker-compose stop ${service}
                echo -e "${GREEN}${service} 容器已停止。${NC}"
            fi
            ;;
        restart)
            echo -e "${GREEN}重启 ${service} 容器...${NC}"
            docker-compose restart ${service}
            ;;
        pull)
            echo -e "${GREEN}拉取最新的 ${service} 镜像...${NC}"
            docker-compose pull ${service}
            docker-compose stop ${service}
            docker-compose rm -f ${service}
            docker-compose up -d ${service}
            docker images -f "dangling=true" -q | xargs -r docker rmi
            docker volume prune -f
           docker-compose logs --tail 300 -f ${service}
            ;;
        log)
            echo -e "${GREEN}查看 ${service} 容器日志...${NC}"
           docker-compose logs --tail 300 -f ${service}
            ;;
        *)
            echo -e "${RED}无效操作: ${action}${NC}"
            ;;
    esac
}

download_compose() {
    create_and_enter_owl_dir

    echo -e "${GREEN}从URL获取docker-compose.yml文件...${NC}"
    curl -o docker-compose.yml ${COMPOSE_URL}
    curl -o .env ${ENV_URL}
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}docker-compose.yml和.env文件下载成功，请修改.env配置文件内的信息。默认文件目录：$OWL_DIR ${NC}"
    else
        echo -e "${RED}docker-compose.yml和.env文件下载失败，请检查URL是否正确。${NC}"
        read -p "按回车键返回菜单..."
        exit 1
    fi
    read -p "按回车键返回菜单..."
}

install_mysql() {
    create_and_enter_owl_dir

    if [ ! -f docker-compose.yml ]; then
        echo -e "${RED}未找到docker-compose.yml文件，请先下载文件。${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi
    
    if [ ! -f .env ]; then
        echo -e "${RED}未找到.env文件，请先下载文件。${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi
    
    check_env || return 1
    
    echo -e "${YELLOW}此选项将安装MySQL${NC}"
    read -p "是否继续？ (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}安装已取消。${NC}"
        read -p "按回车键返回菜单..."
        return
    fi

    load_env

    echo -e "${GREEN}开始安装 MySQL 容器...${NC}"
    docker-compose up -d mysql
    if [ $? -ne 0 ]; then
        echo -e "${RED}MySQL 容器安装过程中发生错误，请检查docker-compose.yml文件是否正确。${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi

    sleep 10 # 等待 MySQL 容器完全启动

    if ! check_mysql_port; then
        echo -e "${RED}MySQL 端口未开放，请检查配置。${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi

    echo -e "${GREEN}MySQL 容器安装并启动成功。${NC}"
    read -p "按回车键返回菜单..."
}

install_and_start_all() {
    create_and_enter_owl_dir

    if [ ! -f .env ]; then
        echo -e "${RED}未找到.env文件，请先下载文件。${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi
    
    check_env || return 1
    load_env
    
    echo -e "${YELLOW}此选项将安装并启动redis, nginx, owl_tiktok_admin, owl_tiktok_web${NC}"
    read -p "是否继续？ (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}安装已取消。${NC}"
        read -p "按回车键返回菜单..."
        return
    fi

    if ! check_mysql_port; then
        echo -e "${RED}MySQL 端口未开放，请检查配置。${NC}"
        read -p "按回车键返回菜单..."
        return 1
    fi

    services=("redis" "owl_tiktok_admin" "owl_tiktok_web" "nginx")
    for service in "${services[@]}"; do
         docker-compose up -d ${service}
    done
    
    echo -e "${GREEN}所有容器已启动。${NC}"
    manage_service log owl_tiktok_admin
}

install_docker() {
    create_and_enter_owl_dir

    if [ ! -f docker-compose.yml ]; then
        echo -e "${RED}未找到docker-compose.yml文件，请先下载文件。${NC}"
        read -p "按回车键返回菜单..."
        return 1
     fi
    
    if [ ! -f .env ]; then
        echo -e "${RED}未找到.env文件，请先下载文件。${NC}"
        read -p "按回车键返回菜单..."
        return 1
     fi
    
    check_env || return 1
    
    echo -e "${YELLOW}此选项将安装docker，docker-compose${NC}"

    echo -e "${GREEN}检查并安装Docker和Docker Compose...${NC}"
    
    # 检测系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s)
    fi
    
    # 检测架构
    architecture=$(uname -m)
    
    if ! command -v docker &> /dev/null; then
        echo -e "${GREEN}安装Docker...${NC}"
        if [ "$OS" == "centos" ]; then
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
        elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/${OS}/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${OS} $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        else
            echo -e "${RED}不支持的操作系统。${NC}"
            return 1
        fi
        sudo systemctl start docker
        sudo systemctl enable docker
        echo -e "${YELLOW}Docker安装完毕。${NC}"
    else
        echo -e "${YELLOW}Docker 已经安装。${NC}"
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}安装Docker Compose...${NC}"
        if [ "$architecture" = "x86_64" ]; then
            # AMD64 架构安装方法
            DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
            sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        else
            # ARM 架构安装方法
            if [ "$OS" == "centos" ]; then
                sudo yum install -y epel-release
                sudo yum install -y python3-pip
                sudo pip3 install docker-compose
            elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
                sudo apt-get update
                sudo apt-get install -y docker-compose
            else
                echo -e "${RED}不支持的操作系统。${NC}"
                return 1
            fi
        fi
        echo -e "${YELLOW}Docker Compose安装完毕。${NC}"
    else
        echo -e "${YELLOW}Docker Compose 已经安装。${NC}"
    fi
}

# 显示菜单
show_menu() {
    echo -e ""
    echo -e "———————${GREEN}【安装】${NC}—————————"
    echo -e "${GREEN}  1.${NC} 下载 docker-compose.yml 和 .env 文件"
    echo -e "${GREEN}  2.${NC} 安装 MySQL"
    echo -e "${GREEN}  3.${NC} 一键安装并启动"
    echo -e ""
    echo -e "———————${GREEN}【tiktok admin】${NC}—————————"
    echo -e "${GREEN}  4.${NC} 更新至最新版本"
    echo -e "${GREEN}  5.${NC} 启动 admin"
    echo -e "${GREEN}  6.${NC} 停止 admin"
    echo -e "${GREEN}  7.${NC} 重启 admin"
    echo -e "${GREEN}  8.${NC} 查看 admin 日志"
    echo -e ""
    echo -e "———————${GREEN}【tiktok web】${NC}—————————"
    echo -e "${GREEN}  9.${NC} 更新至最新版本"
    echo -e "${GREEN} 10.${NC} 启动 web"
    echo -e "${GREEN} 11.${NC} 停止 web"
    echo -e "${GREEN} 12.${NC} 重启 web"
    echo -e "${GREEN} 13.${NC} 查看 web 日志"
    echo -e ""
    echo -e "———————${GREEN}【mysql】${NC}—————————"
    echo -e "${GREEN} 14.${NC} 启动 mysql"
    echo -e "${GREEN} 15.${NC} 停止 mysql"
    echo -e "${GREEN} 16.${NC} 重启 mysql"
    echo -e "${GREEN} 17.${NC} 查看 mysql 日志"
    echo -e ""
    echo -e "———————${GREEN}【nginx】${NC}—————————"
    echo -e "${GREEN} 18.${NC} 启动 nginx"
    echo -e "${GREEN} 19.${NC} 停止 nginx"
    echo -e "${GREEN} 20.${NC} 重启 nginx"
    echo -e "${GREEN} 21.${NC} 查看 nginx 日志"
    echo -e ""
    echo -e "———————${GREEN}【redis】${NC}—————————"
    echo -e "${GREEN} 22.${NC} 启动 redis"
    echo -e "${GREEN} 23.${NC} 停止 redis"
    echo -e "${GREEN} 24.${NC} 重启 redis"
    echo -e "${GREEN} 25.${NC} 查看 redis 日志"
    echo -e "———————————————————"
    echo -e "${GREEN}  0.${YELLOW} 退出${NC}"
}

# 主程序逻辑
while true; do
    StartTitle
    show_menu
    read -p "输入选项 [0-25]: " choice
    case "$choice" in
        1)
            download_compose
            ;;
        2)
            install_docker
            install_mysql
            ;;
        3)
            install_docker
            install_and_start_all
            ;;
        4)
            manage_service pull owl_tiktok_admin
            ;;
        5)
            manage_service start owl_tiktok_admin
            ;;
        6)
            manage_service stop owl_tiktok_admin
            ;;
        7)
            manage_service restart owl_tiktok_admin
            ;;
        8)
            manage_service log owl_tiktok_admin
            ;;
        9)
            manage_service pull owl_tiktok_web
            ;;
        10)
            manage_service start owl_tiktok_web
            ;;
        11)
            manage_service stop owl_tiktok_web
            ;;
        12)
            manage_service restart owl_tiktok_web
            ;;
        13)
            manage_service log owl_tiktok_web
            ;;
        14)
            manage_service start mysql
            ;;
        15)
            manage_service stop mysql
            ;;
        16)
            manage_service restart mysql
            ;;
        17)
            manage_service log mysql
            ;;
        18)
            manage_service start nginx
            ;;
        19)
            manage_service stop nginx
            ;;
        20)
            manage_service restart nginx
            ;;
        21)
            manage_service log nginx
            ;;
        22)
            manage_service start redis
            ;;
        23)
            manage_service stop redis
            ;;
        24)
            manage_service restart redis
            ;;
        25)
            manage_service log redis
            ;;
        0)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新输入。${NC}"
            ;;
    esac
done
