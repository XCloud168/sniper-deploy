#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LICENSE_FILE="license.lic"
LICENSE_SERVER_URL="https://xmsbatedys.masbate.xyz/download-installation-package"  # 许可证服务器URL
COMPOSE_FILE="docker-compose.yml"
DEFAULT_VERSION="latest"  # 默认版本

echo -e "${GREEN}=== 一键部署脚本 ===${NC}"

# 检查脚本是否在正确的目录中运行
check_environment() {
    echo -e "${BLUE}检查部署环境...${NC}"

    # 检查license文件是否存在
    if [[ ! -f "$LICENSE_FILE" ]]; then
        echo -e "${RED}错误: 未找到 $LICENSE_FILE 文件${NC}"
        echo -e "${YELLOW}请确保 $LICENSE_FILE 文件存在于当前目录${NC}"
        exit 1
    fi

    # 检查docker-compose.yml文件是否存在
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo -e "${RED}错误: 未找到 $COMPOSE_FILE 文件${NC}"
        exit 1
    fi

    # 检查Docker是否可用
    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 服务不可用${NC}"
        echo -e "${YELLOW}请先运行 ./prepare.sh 脚本${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ 环境检查通过${NC}"
}

# 验证license并获取下载配置
validate_license() {
    echo -e "${BLUE}验证许可证并获取下载配置...${NC}"

    # 读取license文件内容
    if [[ ! -f "$LICENSE_FILE" ]]; then
        echo -e "${RED}错误: 无法读取 $LICENSE_FILE 文件${NC}"
        exit 1
    fi

    LICENSE_CONTENT=$(cat "$LICENSE_FILE")

    # 获取版本参数，默认为latest
    VERSION=${1:-$DEFAULT_VERSION}
    echo -e "${BLUE}使用版本: $VERSION${NC}"

    # 发送license到服务器获取下载包
    echo -e "${YELLOW}正在验证许可证并获取下载配置...${NC}"

    # 创建临时目录
    TEMP_DIR="temp_downloads"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    # 使用curl发送POST请求获取下载包
    HTTP_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "Cache-Control: no-cache" \
        -H "Accept: */*" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Connection: keep-alive" \
        -d "{\"license_content\":\"$LICENSE_CONTENT\",\"version\":\"$VERSION\"}" \
        "$LICENSE_SERVER_URL" \
        --output data.tar.gz)

    # 提取HTTP状态码
    HTTP_CODE="${HTTP_RESPONSE: -3}"
    echo -e "${BLUE}HTTP状态码: $HTTP_CODE${NC}"

    # 检查HTTP状态码
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "${GREEN}✓ 成功获取下载包${NC}"
    elif [[ "$HTTP_CODE" == "400" ]]; then
        echo -e "${RED}错误: 请求参数错误 (400)${NC}"
        echo -e "${YELLOW}响应内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    elif [[ "$HTTP_CODE" == "401" ]]; then
        echo -e "${RED}错误: 许可证验证失败 (401)${NC}"
        echo -e "${YELLOW}响应内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    elif [[ "$HTTP_CODE" == "403" ]]; then
        echo -e "${RED}错误: 访问被拒绝 (403)${NC}"
        echo -e "${YELLOW}响应内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    elif [[ "$HTTP_CODE" == "404" ]]; then
        echo -e "${RED}错误: 版本不存在 (404)${NC}"
        echo -e "${YELLOW}响应内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    elif [[ "$HTTP_CODE" == "500" ]]; then
        echo -e "${RED}错误: 服务器内部错误 (500)${NC}"
        echo -e "${YELLOW}响应内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    elif [[ "$HTTP_CODE" == "000" ]]; then
        echo -e "${RED}错误: 无法连接到许可证服务器${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    else
        echo -e "${RED}错误: 请求失败，HTTP状态码: $HTTP_CODE${NC}"
        echo -e "${YELLOW}响应内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 检查下载的文件是否为有效的tar.gz文件
    if [[ ! -f "data.tar.gz" ]]; then
        echo -e "${RED}错误: 未获取到下载文件${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 检查文件大小，如果太小可能是JSON错误信息
    FILE_SIZE=$(stat -c%s "data.tar.gz" 2>/dev/null || stat -f%z "data.tar.gz" 2>/dev/null || echo "0")
    if [[ "$FILE_SIZE" -lt 100 ]]; then
        echo -e "${RED}错误: 下载的文件可能不是有效的tar.gz文件${NC}"
        echo -e "${YELLOW}文件内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 尝试检查文件头部，确认是否为tar.gz格式
    if ! file data.tar.gz | grep -q "tar\|gzip\|compressed"; then
        echo -e "${RED}错误: 下载的文件不是有效的压缩文件${NC}"
        echo -e "${YELLOW}文件类型: $(file data.tar.gz)${NC}"
        echo -e "${YELLOW}文件内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 解压下载包
    echo -e "${YELLOW}正在解压下载包...${NC}"
    if tar -xzf data.tar.gz; then
        echo -e "${GREEN}✓ 下载包解压成功${NC}"
    else
        echo -e "${RED}错误: 下载包解压失败${NC}"
        echo -e "${YELLOW}文件内容:${NC}"
        cat data.tar.gz
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 检查解压后的文件
    if [[ ! -f "public.pem" ]] || [[ ! -f "fernet.key" ]] || [[ ! -f "download_config.json" ]]; then
        echo -e "${RED}错误: 下载包内容不完整${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 创建config目录并复制配置文件
    echo -e "${YELLOW}正在配置安全文件...${NC}"
    mkdir -p ../config
    cp public.pem ../config/
    cp fernet.key ../config/
    echo -e "${GREEN}✓ 安全文件配置完成${NC}"

    # 读取下载配置
    if [[ -f "download_config.json" ]]; then
        echo -e "${YELLOW}正在读取下载配置...${NC}"

        # 使用jq解析JSON（如果可用）
        if command -v jq &> /dev/null; then
            FRONTEND_URL=$(jq -r '.download_urls.frontend' download_config.json)
            API_URL=$(jq -r '.download_urls.api' download_config.json)
            VERSION=$(jq -r '.version' download_config.json)
        else
            # 使用grep和sed解析JSON
            FRONTEND_URL=$(grep -o '"frontend":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
            API_URL=$(grep -o '"api":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
            VERSION=$(grep -o '"version":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
        fi

        echo -e "${GREEN}✓ 下载配置读取成功${NC}"
        echo -e "${BLUE}版本: $VERSION${NC}"
        echo -e "${BLUE}Frontend URL: $FRONTEND_URL${NC}"
        echo -e "${BLUE}API URL: $API_URL${NC}"
    else
        echo -e "${RED}错误: 无法读取下载配置文件${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    cd ..
}

# 下载Docker镜像
download_images() {
    echo -e "${BLUE}下载Docker镜像...${NC}"

    # 进入临时目录
    cd "$TEMP_DIR"

    # 显示版本信息
    echo -e "${BLUE}下载版本: $VERSION${NC}"

    # 下载镜像文件
    for url in "$FRONTEND_URL" "$API_URL"; do
        filename=$(basename "$url" | cut -d'?' -f1)  # 移除URL参数
        echo -e "${YELLOW}正在下载 $filename (版本: $VERSION)...${NC}"

        if curl -L -o "$filename" "$url"; then
            echo -e "${GREEN}✓ $filename 下载完成${NC}"

            # 显示文件大小
            FILE_SIZE=$(ls -lh "$filename" | awk '{print $5}')
            echo -e "${BLUE}文件大小: $FILE_SIZE${NC}"
        else
            echo -e "${RED}✗ $filename 下载失败${NC}"
            cd ..
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    done

    cd ..
}

# 加载Docker镜像
load_images() {
    echo -e "${BLUE}加载Docker镜像...${NC}"

    cd "$TEMP_DIR"

    # 显示版本信息
    echo -e "${BLUE}部署版本: $VERSION${NC}"

    # 只加载从S3下载的Docker镜像文件，排除data.tar.gz
    for file in frontend-$VERSION.tar.gz api-$VERSION.tar.gz; do
        if [[ -f "$file" ]]; then
            echo -e "${YELLOW}正在加载 $file (版本: $VERSION)...${NC}"

            if docker load -i "$file"; then
                echo -e "${GREEN}✓ $file 加载成功${NC}"

                # 获取加载的镜像信息
                IMAGE_INFO=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "sniper-(frontend|api)" | tail -1)
                if [[ -n "$IMAGE_INFO" ]]; then
                    echo -e "${BLUE}镜像信息: $IMAGE_INFO${NC}"
                fi

                                # 如果是latest版本，确保镜像标签为latest
                if [[ "$VERSION" == "latest" ]]; then
                    echo -e "${YELLOW}处理latest版本标签...${NC}"

                    # 获取刚加载的镜像（通过docker load的输出或最新创建的镜像）
                    if [[ "$file" == *"frontend"* ]]; then
                        # 查找最新创建的前端镜像
                        LOADED_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" --filter "reference=sniper-frontend" --filter "dangling=false" | head -1)
                        if [[ -n "$LOADED_IMAGE" ]]; then
                            # 如果镜像标签不是latest，重新标记
                            if [[ "$LOADED_IMAGE" != "sniper-frontend:latest" ]]; then
                                echo -e "${YELLOW}重新标记前端镜像为latest...${NC}"
                                echo -e "${BLUE}原镜像: $LOADED_IMAGE${NC}"
                                docker tag "$LOADED_IMAGE" "sniper-frontend:latest"
                                echo -e "${GREEN}✓ 前端镜像已标记为 sniper-frontend:latest${NC}"
                            else
                                echo -e "${GREEN}✓ 前端镜像已经是 sniper-frontend:latest${NC}"
                            fi
                        else
                            echo -e "${YELLOW}⚠ 未找到前端镜像${NC}"
                        fi
                    elif [[ "$file" == *"api"* ]]; then
                        # 查找最新创建的API镜像
                        LOADED_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" --filter "reference=sniper-api" --filter "dangling=false" | head -1)
                        if [[ -n "$LOADED_IMAGE" ]]; then
                            # 如果镜像标签不是latest，重新标记
                            if [[ "$LOADED_IMAGE" != "sniper-api:latest" ]]; then
                                echo -e "${YELLOW}重新标记API镜像为latest...${NC}"
                                echo -e "${BLUE}原镜像: $LOADED_IMAGE${NC}"
                                docker tag "$LOADED_IMAGE" "sniper-api:latest"
                                echo -e "${GREEN}✓ API镜像已标记为 sniper-api:latest${NC}"
                            else
                                echo -e "${GREEN}✓ API镜像已经是 sniper-api:latest${NC}"
                            fi
                        else
                            echo -e "${YELLOW}⚠ 未找到API镜像${NC}"
                        fi
                    fi
                fi
            else
                echo -e "${RED}✗ $file 加载失败${NC}"
                cd ..
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        fi
    done

    cd ..

    # 验证加载的镜像
    if ! verify_loaded_images; then
        echo -e "${RED}✗ 镜像验证失败${NC}"
        cd ..
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 清理临时文件
    echo -e "${YELLOW}清理临时文件...${NC}"
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}✓ 临时文件清理完成${NC}"
}

# 验证加载的镜像
verify_loaded_images() {
    echo -e "${BLUE}验证加载的镜像...${NC}"

    # 设置版本环境变量（使用传入的版本或默认版本）
    VERSION=${VERSION:-$DEFAULT_VERSION}
    echo -e "${BLUE}验证版本: $VERSION${NC}"

    # 检查是否有对应版本的前端镜像
    FRONTEND_IMAGE="sniper-frontend:$VERSION"
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$FRONTEND_IMAGE$"; then
        echo -e "${GREEN}✓ 前端镜像: $FRONTEND_IMAGE${NC}"
    else
        # 如果是latest版本，检查是否有任何前端镜像
        if [[ "$VERSION" == "latest" ]]; then
            FRONTEND_EXISTS=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "sniper-frontend" | head -1)
            if [[ -n "$FRONTEND_EXISTS" ]]; then
                echo -e "${GREEN}✓ 前端镜像: $FRONTEND_EXISTS (latest版本)${NC}"
                # 确保有latest标签
                if [[ "$FRONTEND_EXISTS" != "sniper-frontend:latest" ]]; then
                    echo -e "${YELLOW}创建latest标签...${NC}"
                    docker tag "$FRONTEND_EXISTS" "sniper-frontend:latest"
                    echo -e "${GREEN}✓ 前端镜像已标记为 sniper-frontend:latest${NC}"
                fi
            else
                echo -e "${RED}✗ 未找到前端镜像${NC}"
                return 1
            fi
        else
            echo -e "${RED}✗ 未找到前端镜像: $FRONTEND_IMAGE${NC}"
            echo -e "${YELLOW}可用的前端镜像:${NC}"
            docker images --format "{{.Repository}}:{{.Tag}}" | grep "sniper-frontend" || echo -e "${YELLOW}暂无前端镜像${NC}"
            return 1
        fi
    fi

    # 检查是否有对应版本的API镜像
    API_IMAGE="sniper-api:$VERSION"
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$API_IMAGE$"; then
        echo -e "${GREEN}✓ API镜像: $API_IMAGE${NC}"
    else
        # 如果是latest版本，检查是否有任何API镜像
        if [[ "$VERSION" == "latest" ]]; then
            API_EXISTS=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "sniper-api" | head -1)
            if [[ -n "$API_EXISTS" ]]; then
                echo -e "${GREEN}✓ API镜像: $API_EXISTS (latest版本)${NC}"
                # 确保有latest标签
                if [[ "$API_EXISTS" != "sniper-api:latest" ]]; then
                    echo -e "${YELLOW}创建latest标签...${NC}"
                    docker tag "$API_EXISTS" "sniper-api:latest"
                    echo -e "${GREEN}✓ API镜像已标记为 sniper-api:latest${NC}"
                fi
            else
                echo -e "${RED}✗ 未找到API镜像${NC}"
                return 1
            fi
        else
            echo -e "${RED}✗ 未找到API镜像: $API_IMAGE${NC}"
            echo -e "${YELLOW}可用的API镜像:${NC}"
            docker images --format "{{.Repository}}:{{.Tag}}" | grep "sniper-api" || echo -e "${YELLOW}暂无API镜像${NC}"
            return 1
        fi
    fi

    # 显示所有相关镜像
    echo -e "${BLUE}已加载的镜像列表:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "(sniper-frontend|sniper-api)" || echo -e "${YELLOW}暂无相关镜像${NC}"
}

# 停止现有服务
stop_existing_services() {
    echo -e "${BLUE}停止现有服务...${NC}"

    # 确保在正确的目录中
    cd "$SCRIPT_DIR"

    # 设置版本环境变量（使用传入的版本或默认版本）
    VERSION=${VERSION:-$DEFAULT_VERSION}
    export VERSION="$VERSION"
    echo -e "${BLUE}使用版本: $VERSION${NC}"

    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        echo -e "${YELLOW}正在停止现有服务...${NC}"
        docker-compose -f "$COMPOSE_FILE" down
        echo -e "${GREEN}✓ 现有服务已停止${NC}"
    else
        echo -e "${GREEN}✓ 没有运行中的服务${NC}"
    fi
}

# 执行数据库迁移
run_database_migration() {
    echo -e "${BLUE}执行数据库迁移...${NC}"

    # 确保在正确的目录中
    cd "$SCRIPT_DIR"

    # 设置版本环境变量（使用传入的版本或默认版本）
    VERSION=${VERSION:-$DEFAULT_VERSION}
    export VERSION="$VERSION"
    echo -e "${BLUE}使用版本: $VERSION${NC}"

    # 等待PostgreSQL健康检查通过
    echo -e "${YELLOW}等待PostgreSQL健康检查通过...${NC}"
    timeout=60
    counter=0
    while [ $counter -lt $timeout ]; do
        if docker-compose -f "$COMPOSE_FILE" ps postgres | grep -q "healthy"; then
            echo -e "${GREEN}✓ PostgreSQL服务已就绪${NC}"
            break
        fi
        echo -e "${YELLOW}等待PostgreSQL服务就绪... ($counter/$timeout)${NC}"
        sleep 2
        counter=$((counter + 2))
    done

    if [ $counter -ge $timeout ]; then
        echo -e "${RED}✗ PostgreSQL服务启动超时${NC}"
        echo -e "${YELLOW}查看PostgreSQL日志:${NC}"
        docker-compose -f "$COMPOSE_FILE" logs postgres
        exit 1
    fi

    # 执行数据库迁移
    echo -e "${YELLOW}正在执行数据库迁移...${NC}"
    if docker-compose -f "$COMPOSE_FILE" run --rm db-migrate; then
        echo -e "${GREEN}✓ 数据库迁移成功${NC}"
    else
        echo -e "${RED}✗ 数据库迁移失败${NC}"
        echo -e "${YELLOW}查看迁移日志:${NC}"
        docker-compose -f "$COMPOSE_FILE" logs db-migrate
        exit 1
    fi
}

# 启动服务
start_services() {
    echo -e "${BLUE}启动服务...${NC}"

    # 确保在正确的目录中
    cd "$SCRIPT_DIR"

    # 创建必要的目录
    mkdir -p data/postgres_data
    mkdir -p logs
    mkdir -p config

    # 检查.env文件是否存在
    if [[ ! -f ".env" ]]; then
        echo -e "${YELLOW}警告: 未找到 .env 文件${NC}"
        echo -e "${YELLOW}请确保创建 .env 文件并配置必要的环境变量${NC}"
    fi

    # 设置版本环境变量（使用传入的版本或默认版本）
    VERSION=${VERSION:-$DEFAULT_VERSION}
    export VERSION="$VERSION"
    echo -e "${BLUE}使用版本: $VERSION${NC}"

    # 第一步：启动 postgres 和 redis
    echo -e "${YELLOW}第一步：启动 postgres 和 redis 服务...${NC}"
    if docker-compose -f "$COMPOSE_FILE" up -d postgres redis --remove-orphans; then
        echo -e "${GREEN}✓ postgres 和 redis 服务启动成功${NC}"
    else
        echo -e "${RED}✗ postgres 和 redis 服务启动失败${NC}"
        exit 1
    fi

    sleep 10

    # 第二步：执行数据库迁移
    echo -e "${YELLOW}第二步：执行数据库迁移...${NC}"
    run_database_migration

    # 第三步：启动其他服务
    echo -e "${YELLOW}第三步：启动其他服务...${NC}"
    if docker-compose -f "$COMPOSE_FILE" up -d --scale db-migrate=0; then
        echo -e "${GREEN}✓ 所有服务启动成功${NC}"

        # 显示服务状态
        echo -e "${BLUE}服务状态:${NC}"
        docker-compose -f "$COMPOSE_FILE" ps

        echo -e "${GREEN}部署完成！${NC}"
        echo -e "${BLUE}部署版本: $VERSION${NC}"
        echo -e "${BLUE}服务访问地址:${NC}"
        echo -e "${YELLOW} http://localhost:9000${NC}"
    else
        echo -e "${RED}✗ 其他服务启动失败${NC}"
        exit 1
    fi
}

# 显示服务日志
show_logs() {
    echo -e "${BLUE}显示服务日志 (按 Ctrl+C 退出)...${NC}"

    # 确保在正确的目录中
    cd "$SCRIPT_DIR"

    # 设置版本环境变量（使用传入的版本或默认版本）
    VERSION=${VERSION:-$DEFAULT_VERSION}
    export VERSION="$VERSION"
    echo -e "${BLUE}使用版本: $VERSION${NC}"

    docker-compose -f "$COMPOSE_FILE" logs -f --tail 100
}

# 主函数
main() {
    echo -e "${GREEN}开始部署流程...${NC}"

    # 获取版本参数（优先使用环境变量，然后是命令行参数，最后是默认值）
    VERSION=${VERSION:-${1:-$DEFAULT_VERSION}}
    echo -e "${BLUE}部署版本: $VERSION${NC}"

    # 检查环境
    check_environment

    # 验证license
    validate_license "$VERSION"

    # 下载镜像
    download_images

    # 加载镜像
    load_images

    # 停止现有服务
    stop_existing_services

    # 启动服务
    start_services

    echo -e "${GREEN}=== 部署完成 ===${NC}"
    echo -e "${YELLOW}提示: 运行 'docker-compose logs -f --tail 100' 查看服务日志${NC}"
    echo -e "${YELLOW}提示: 运行 'docker-compose down' 停止服务${NC}"
}

# 处理命令行参数
case "${1:-}" in
    "start")
        # 使用本地镜像启动服务
        echo -e "${GREEN}=== 使用本地镜像启动服务 ===${NC}"

        # 获取版本参数（优先使用环境变量，然后是命令行参数，最后是默认值）
        VERSION=${VERSION:-${2:-$DEFAULT_VERSION}}
        echo -e "${BLUE}启动版本: $VERSION${NC}"

        # 检查环境
        check_environment

        # 验证本地镜像是否存在
        if ! verify_loaded_images; then
            echo -e "${RED}错误: 本地镜像验证失败${NC}"
            echo -e "${YELLOW}请先运行 ./deploy.sh [版本] 下载并加载镜像${NC}"
            exit 1
        fi

        # 停止现有服务
        stop_existing_services

        # 启动服务
        start_services

        echo -e "${GREEN}=== 本地启动完成 ===${NC}"
        ;;
    "logs")
        # 设置默认版本
        VERSION=${VERSION:-$DEFAULT_VERSION}
        export VERSION="$VERSION"
        show_logs
        ;;
    "stop")
        # 确保在正确的目录中
        cd "$SCRIPT_DIR"
        # 设置默认版本
        VERSION=${VERSION:-$DEFAULT_VERSION}
        export VERSION="$VERSION"
        echo -e "${BLUE}使用版本: $VERSION${NC}"
        docker-compose -f "$COMPOSE_FILE" down
        echo -e "${GREEN}服务已停止${NC}"
        ;;
    "restart")
        # 确保在正确的目录中
        cd "$SCRIPT_DIR"
        # 设置默认版本
        VERSION=${VERSION:-$DEFAULT_VERSION}
        export VERSION="$VERSION"
        echo -e "${BLUE}使用版本: $VERSION${NC}"
        docker-compose -f "$COMPOSE_FILE" restart
        echo -e "${GREEN}服务已重启${NC}"
        ;;
    "status")
        # 确保在正确的目录中
        cd "$SCRIPT_DIR"
        # 设置默认版本
        VERSION=${VERSION:-$DEFAULT_VERSION}
        export VERSION="$VERSION"
        echo -e "${BLUE}使用版本: $VERSION${NC}"
        docker-compose -f "$COMPOSE_FILE" ps
        ;;
    "migrate")
        # 确保在正确的目录中
        cd "$SCRIPT_DIR"
        # 设置默认版本
        VERSION=${VERSION:-$DEFAULT_VERSION}
        export VERSION="$VERSION"
        echo -e "${BLUE}使用版本: $VERSION${NC}"
        run_database_migration
        echo -e "${GREEN}数据库迁移完成${NC}"
        ;;
    "help"|"-h"|"--help")
        echo -e "${GREEN}=== 部署脚本使用说明 ===${NC}"
        echo -e "${BLUE}用法:${NC}"
        echo -e "  ./deploy.sh [版本]     # 部署指定版本，默认为latest"
        echo -e "  ./deploy.sh start [版本] # 使用本地镜像启动服务"
        echo -e "  ./deploy.sh logs       # 查看服务日志"
        echo -e "  ./deploy.sh stop       # 停止服务"
        echo -e "  ./deploy.sh restart    # 重启服务"
        echo -e "  ./deploy.sh status     # 查看服务状态"
        echo -e "  ./deploy.sh migrate    # 执行数据库迁移"
        echo -e "  ./deploy.sh help       # 显示此帮助信息"
        echo -e ""
        echo -e "${BLUE}示例:${NC}"
        echo -e "  ./deploy.sh            # 部署最新版本"
        echo -e "  ./deploy.sh 0.0.1     # 部署0.0.1版本"
        echo -e "  ./deploy.sh latest     # 部署最新版本"
        echo -e "  ./deploy.sh start      # 使用本地镜像启动最新版本"
        echo -e "  ./deploy.sh start 0.0.1 # 使用本地镜像启动0.0.1版本"
        ;;
    *)
        main "$1"
        ;;
esac