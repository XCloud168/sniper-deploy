#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Sniper Bot"
VERSION="0.0.7"  # 固定版本号，确保每次都是最新版本
LICENSE_FILE="license.lic"
LICENSE_SERVER_URL="https://xmsbatedys.masbate.xyz/download-installation-package"
COMPOSE_FILE="docker-compose.yml"

# 打印欢迎信息
print_welcome() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                    $PROJECT_NAME 安装程序                    ║"
    echo "║                                                              ║"
    echo "║                    版本: $VERSION                           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}欢迎使用 $PROJECT_NAME 安装程序！${NC}"
    echo -e "${YELLOW}此脚本将帮助您快速部署 $PROJECT_NAME 到您的系统。${NC}"
    echo ""
}

# 检查系统要求
check_system_requirements() {
    echo -e "${BLUE}🔍 检查系统要求...${NC}"

    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${GREEN}✓ 操作系统: Linux${NC}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}✓ 操作系统: macOS${NC}"
    else
        echo -e "${YELLOW}⚠ 警告: 未识别的操作系统 ($OSTYPE)${NC}"
    fi

    # 检查Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "${GREEN}✓ Docker: $DOCKER_VERSION${NC}"

        # 检查Docker服务是否运行
        if docker info &> /dev/null; then
            echo -e "${GREEN}✓ Docker服务正在运行${NC}"
        else
            echo -e "${RED}✗ Docker服务未运行${NC}"
            echo -e "${YELLOW}请启动Docker服务后重试${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ Docker未安装${NC}"
        echo -e "${YELLOW}请先安装Docker: https://docs.docker.com/get-docker/${NC}"
        exit 1
    fi

    # 检查Docker Compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        echo -e "${GREEN}✓ Docker Compose: $COMPOSE_VERSION${NC}"
    else
        echo -e "${RED}✗ Docker Compose未安装或不可用${NC}"
        echo -e "${YELLOW}请确保Docker版本支持compose命令${NC}"
        exit 1
    fi

    # 检查curl
    if command -v curl &> /dev/null; then
        echo -e "${GREEN}✓ curl: 可用${NC}"
    else
        echo -e "${RED}✗ curl未安装${NC}"
        echo -e "${YELLOW}请先安装curl${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ 系统要求检查完成${NC}"
    echo ""
}

# 检查必要文件
check_required_files() {
    echo -e "${BLUE}📁 检查必要文件...${NC}"

    # 检查license文件
    if [[ ! -f "$LICENSE_FILE" ]]; then
        echo -e "${RED}✗ 未找到 $LICENSE_FILE 文件${NC}"
        echo -e "${YELLOW}请确保 $LICENSE_FILE 文件存在于当前目录${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 找到 $LICENSE_FILE${NC}"

    # 检查docker-compose.yml
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo -e "${RED}✗ 未找到 $COMPOSE_FILE 文件${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 找到 $COMPOSE_FILE${NC}"

    echo -e "${GREEN}✓ 文件检查完成${NC}"
    echo ""
}

# 创建环境配置文件
setup_environment() {
    echo -e "${BLUE}⚙️  配置环境...${NC}"

    # 创建必要的目录
    mkdir -p data/postgres_data
    mkdir -p logs
    mkdir -p config

    # 检查.env文件
    if [[ ! -f ".env" ]]; then
        echo -e "${YELLOW}⚠ 未找到 .env 文件，正在创建...${NC}"
        if [[ -f "env.example" ]]; then
            cp env.example .env
            echo -e "${GREEN}✓ 已从 env.example 创建 .env 文件${NC}"
            echo -e "${YELLOW}请根据需要编辑 .env 文件中的配置${NC}"
        else
            echo -e "${YELLOW}⚠ 未找到 env.example 文件，请手动创建 .env 文件${NC}"
        fi
    else
        echo -e "${GREEN}✓ 找到 .env 文件${NC}"
    fi

    echo -e "${GREEN}✓ 环境配置完成${NC}"
    echo ""
}

# 验证许可证并下载镜像
download_images() {
    echo -e "${BLUE}📦 验证许可证并下载镜像...${NC}"

    # 读取license文件
    if [[ ! -f "$LICENSE_FILE" ]]; then
        echo -e "${RED}✗ 无法读取 $LICENSE_FILE 文件${NC}"
        exit 1
    fi

    LICENSE_CONTENT=$(cat "$LICENSE_FILE")

    # 创建临时目录
    TEMP_DIR="temp_downloads"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    echo -e "${YELLOW}正在验证许可证并获取下载配置...${NC}"

    # 发送请求获取下载包
    HTTP_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "Cache-Control: no-cache" \
        -H "Accept: */*" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Connection: keep-alive" \
        -d "{\"license_content\":\"$LICENSE_CONTENT\",\"version\":\"$VERSION\"}" \
        "$LICENSE_SERVER_URL" \
        --output data.zip)

    # 检查响应
    HTTP_CODE="${HTTP_RESPONSE: -3}"
    if [[ "$HTTP_CODE" != "200" ]]; then
        echo -e "${RED}✗ 许可证验证失败 (HTTP $HTTP_CODE)${NC}"
        if [[ -f "data.zip" ]]; then
            echo -e "${YELLOW}错误详情:${NC}"
            cat data.zip
        fi
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    echo -e "${GREEN}✓ 许可证验证成功${NC}"

    # 解压下载包
    echo -e "${YELLOW}正在解压下载包...${NC}"
    if ! python3 -m zipfile -e data.zip $TEMP_DIR; then
        echo -e "${RED}✗ 下载包解压失败${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 检查必要文件
    if [[ ! -f "public.pem" ]] || [[ ! -f "fernet.key" ]] || [[ ! -f "download_config.json" ]]; then
        echo -e "${RED}✗ 下载包内容不完整${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 复制配置文件
    cp public.pem ../config/
    cp fernet.key ../config/

    # 读取下载配置
    if command -v jq &> /dev/null; then
        FRONTEND_URL=$(jq -r '.download_urls.frontend' download_config.json)
        API_URL=$(jq -r '.download_urls.api' download_config.json)
    else
        FRONTEND_URL=$(grep -o '"frontend":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
        API_URL=$(grep -o '"api":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
    fi

    echo -e "${GREEN}✓ 下载配置读取成功${NC}"

    # 下载镜像
    echo -e "${YELLOW}正在下载Docker镜像...${NC}"
    for url in "$FRONTEND_URL" "$API_URL"; do
        filename=$(basename "$url" | cut -d'?' -f1)
        echo -e "${YELLOW}下载 $filename...${NC}"

        if curl -L -o "$filename" "$url"; then
            echo -e "${GREEN}✓ $filename 下载完成${NC}"

            # 加载镜像
            echo -e "${YELLOW}加载 $filename...${NC}"
            if docker load -i "$filename"; then
                echo -e "${GREEN}✓ $filename 加载成功${NC}"
            else
                echo -e "${RED}✗ $filename 加载失败${NC}"
                cd ..
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        else
            echo -e "${RED}✗ $filename 下载失败${NC}"
            cd ..
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    done

    # 清理临时文件
    cd ..
    rm -rf "$TEMP_DIR"

    echo -e "${GREEN}✓ 镜像下载和加载完成${NC}"
    echo ""
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动服务...${NC}"

    # 设置版本环境变量
    export VERSION="$VERSION"

    # 停止现有服务
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        echo -e "${YELLOW}停止现有服务...${NC}"
        docker compose -f "$COMPOSE_FILE" down
    fi

    # 启动基础服务
    echo -e "${YELLOW}启动数据库和缓存服务...${NC}"
    if ! docker compose -f "$COMPOSE_FILE" up -d postgres redis; then
        echo -e "${RED}✗ 基础服务启动失败${NC}"
        exit 1
    fi

    # 等待数据库就绪
    echo -e "${YELLOW}等待数据库就绪...${NC}"
    timeout=60
    counter=0
    while [ $counter -lt $timeout ]; do
        if docker compose -f "$COMPOSE_FILE" ps postgres | grep -q "(healthy)"; then
            echo -e "${GREEN}✓ 数据库已就绪${NC}"
            break
        fi
        echo -e "${YELLOW}等待数据库就绪... ($counter/$timeout)${NC}"
        sleep 2
        counter=$((counter + 2))
    done

    if [ $counter -ge $timeout ]; then
        echo -e "${RED}✗ 数据库启动超时${NC}"
        exit 1
    fi

    # 执行数据库迁移
    echo -e "${YELLOW}执行数据库迁移...${NC}"
    sleep 1
    if ! docker compose -f "$COMPOSE_FILE" run --rm db-migrate; then
        echo -e "${RED}✗ 数据库迁移失败${NC}"
        exit 1
    fi

    # 启动所有服务
    echo -e "${YELLOW}启动所有服务...${NC}"
    if ! docker compose -f "$COMPOSE_FILE" up -d --scale db-migrate=0; then
        echo -e "${RED}✗ 服务启动失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ 所有服务启动成功${NC}"
    echo ""
}

# 读取默认管理员用户配置
read_admin_config() {
    local username="admin"
    local password="123456"
    local email="admin@sniper-bot.com"

    # 如果.env文件存在，尝试读取配置
    if [[ -f ".env" ]]; then
        # 读取用户名
        if grep -q "^DEFAULT_ADMIN_USERNAME=" .env; then
            username=$(grep "^DEFAULT_ADMIN_USERNAME=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        fi

        # 读取密码
        if grep -q "^DEFAULT_ADMIN_PASSWORD=" .env; then
            password=$(grep "^DEFAULT_ADMIN_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        fi

        # 读取邮箱
        if grep -q "^DEFAULT_ADMIN_EMAIL=" .env; then
            email=$(grep "^DEFAULT_ADMIN_EMAIL=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        fi
    fi

    # 返回配置（通过全局变量）
    ADMIN_USERNAME="$username"
    ADMIN_PASSWORD="$password"
    ADMIN_EMAIL="$email"
}

# 显示部署结果
show_deployment_result() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                    🎉 部署完成！                            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${CYAN}📊 服务状态:${NC}"
    docker compose -f "$COMPOSE_FILE" ps

    echo ""
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo -e "${YELLOW}前端界面: http://localhost:9000${NC}"

    # 读取并显示管理员配置
    read_admin_config
    echo -e "${YELLOW}初始用户名: $ADMIN_USERNAME${NC}"
    echo -e "${YELLOW}初始密码: $ADMIN_PASSWORD${NC}"
    echo -e "${YELLOW}管理员邮箱: $ADMIN_EMAIL${NC}"

    echo ""
    echo -e "${CYAN}📝 常用命令:${NC}"
    echo -e "${YELLOW}查看日志: docker compose logs -f${NC}"
    echo -e "${YELLOW}停止服务: docker compose down${NC}"
    echo -e "${YELLOW}重启服务: docker compose restart${NC}"
    echo -e "${YELLOW}查看状态: docker compose ps${NC}"

    echo ""
    echo -e "${GREEN}感谢使用 $PROJECT_NAME！${NC}"
}

# 主函数
main() {
    print_welcome
    check_system_requirements
    check_required_files
    setup_environment
    download_images
    start_services
    show_deployment_result
}

# 处理命令行参数
case "${1:-}" in
    "help"|"-h"|"--help")
        echo -e "${GREEN}=== $PROJECT_NAME 安装程序帮助 ===${NC}"
        echo -e "${BLUE}用法:${NC}"
        echo -e "  ./setup.sh          # 安装并启动 $PROJECT_NAME"
        echo -e "  ./setup.sh help     # 显示此帮助信息"
        echo ""
        echo -e "${BLUE}系统要求:${NC}"
        echo -e "  • Docker 20.10+"
        echo -e "  • Docker Compose 2.0+"
        echo -e "  • curl"
        echo -e "  • Linux 或 macOS"
        echo ""
        echo -e "${BLUE}必要文件:${NC}"
        echo -e "  • license.lic (许可证文件)"
        echo -e "  • docker-compose.yml"
        echo -e "  • env.example (可选，用于创建 .env)"
        ;;
    *)
        main
        ;;
esac
