#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 版本信息检查脚本 ===${NC}"

# 检查配置文件中的版本信息
check_config_version() {
    echo -e "${BLUE}检查配置文件版本信息...${NC}"

    if [[ -f "download_config.json" ]]; then
        echo -e "${GREEN}✓ 找到下载配置文件${NC}"

        # 使用jq解析JSON（如果可用）
        if command -v jq &> /dev/null; then
            CONFIG_VERSION=$(jq -r '.version' download_config.json)
            PACKAGE_VERSION=$(jq -r '.package_version' download_config.json)
            CREATED_AT=$(jq -r '.created_at' download_config.json)

            echo -e "${BLUE}配置版本: $CONFIG_VERSION${NC}"
            echo -e "${BLUE}包版本: $PACKAGE_VERSION${NC}"
            echo -e "${BLUE}创建时间: $CREATED_AT${NC}"
        else
            # 使用grep和sed解析JSON
            CONFIG_VERSION=$(grep -o '"version":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
            PACKAGE_VERSION=$(grep -o '"package_version":\s*"[^"]*"' download_config.json | cut -d'"' -f4)
            CREATED_AT=$(grep -o '"created_at":\s*"[^"]*"' download_config.json | cut -d'"' -f4)

            echo -e "${BLUE}配置版本: $CONFIG_VERSION${NC}"
            echo -e "${BLUE}包版本: $PACKAGE_VERSION${NC}"
            echo -e "${BLUE}创建时间: $CREATED_AT${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 未找到下载配置文件${NC}"
    fi
}

# 检查Docker镜像版本
check_docker_images() {
    echo -e "${BLUE}检查Docker镜像版本...${NC}"

    # 检查前端镜像
    FRONTEND_IMAGES=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "frontend|sniper")
    if [[ -n "$FRONTEND_IMAGES" ]]; then
        echo -e "${GREEN}✓ 前端镜像:${NC}"
        echo "$FRONTEND_IMAGES"
    else
        echo -e "${YELLOW}⚠ 未找到前端镜像${NC}"
    fi

    echo ""

    # 检查API镜像
    API_IMAGES=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "api|sniper")
    if [[ -n "$API_IMAGES" ]]; then
        echo -e "${GREEN}✓ API镜像:${NC}"
        echo "$API_IMAGES"
    else
        echo -e "${YELLOW}⚠ 未找到API镜像${NC}"
    fi

    echo ""

    # 检查所有相关镜像
    ALL_IMAGES=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "(frontend|api|sniper)")
    if [[ -n "$ALL_IMAGES" ]]; then
        echo -e "${GREEN}✓ 所有相关镜像:${NC}"
        echo "$ALL_IMAGES"
    else
        echo -e "${YELLOW}⚠ 未找到相关镜像${NC}"
    fi
}

# 检查运行中的容器版本
check_running_containers() {
    echo -e "${BLUE}检查运行中的容器...${NC}"

    # 检查docker-compose服务
    if [[ -f "docker-compose.yml" ]]; then
        echo -e "${GREEN}✓ Docker Compose服务状态:${NC}"
        docker-compose ps

        echo ""

        # 获取容器镜像信息
        echo -e "${GREEN}✓ 容器镜像信息:${NC}"
        docker-compose images
    else
        echo -e "${YELLOW}⚠ 未找到docker-compose.yml文件${NC}"
    fi
}

# 检查许可证信息
check_license_info() {
    echo -e "${BLUE}检查许可证信息...${NC}"

    if [[ -f "license.lic" ]]; then
        echo -e "${GREEN}✓ 许可证文件存在${NC}"

        # 显示许可证文件大小
        LICENSE_SIZE=$(ls -lh license.lic | awk '{print $5}')
        echo -e "${BLUE}许可证文件大小: $LICENSE_SIZE${NC}"

        # 显示许可证文件的前几个字符（脱敏）
        LICENSE_PREVIEW=$(head -c 20 license.lic)
        echo -e "${BLUE}许可证预览: ${LICENSE_PREVIEW}...${NC}"
    else
        echo -e "${RED}✗ 许可证文件不存在${NC}"
    fi
}

# 检查配置文件
check_config_files() {
    echo -e "${BLUE}检查配置文件...${NC}"

    if [[ -d "config" ]]; then
        echo -e "${GREEN}✓ 配置目录存在${NC}"

        # 检查public.pem
        if [[ -f "config/public.pem" ]]; then
            echo -e "${GREEN}✓ public.pem 存在${NC}"
            PEM_SIZE=$(ls -lh config/public.pem | awk '{print $5}')
            echo -e "${BLUE}文件大小: $PEM_SIZE${NC}"
        else
            echo -e "${YELLOW}⚠ public.pem 不存在${NC}"
        fi

        # 检查fernet.key
        if [[ -f "config/fernet.key" ]]; then
            echo -e "${GREEN}✓ fernet.key 存在${NC}"
            KEY_SIZE=$(ls -lh config/fernet.key | awk '{print $5}')
            echo -e "${BLUE}文件大小: $KEY_SIZE${NC}"
        else
            echo -e "${YELLOW}⚠ fernet.key 不存在${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
    fi
}

# 主函数
main() {
    echo -e "${GREEN}开始版本信息检查...${NC}"
    echo ""

    # 检查许可证信息
    check_license_info
    echo ""

    # 检查配置文件
    check_config_files
    echo ""

    # 检查配置文件版本
    check_config_version
    echo ""

    # 检查Docker镜像
    check_docker_images
    echo ""

    # 检查运行中的容器
    check_running_containers
    echo ""

    echo -e "${GREEN}=== 版本信息检查完成 ===${NC}"
}

# 处理命令行参数
case "${1:-}" in
    "images")
        check_docker_images
        ;;
    "containers")
        check_running_containers
        ;;
    "config")
        check_config_version
        ;;
    "license")
        check_license_info
        ;;
    "files")
        check_config_files
        ;;
    "help"|"-h"|"--help")
        echo -e "${GREEN}=== 版本检查脚本使用说明 ===${NC}"
        echo -e "${BLUE}用法:${NC}"
        echo -e "  ./check_version.sh        # 完整版本检查"
        echo -e "  ./check_version.sh images # 只检查Docker镜像"
        echo -e "  ./check_version.sh containers # 只检查运行中的容器"
        echo -e "  ./check_version.sh config # 只检查配置文件版本"
        echo -e "  ./check_version.sh license # 只检查许可证信息"
        echo -e "  ./check_version.sh files # 只检查配置文件"
        echo -e "  ./check_version.sh help   # 显示此帮助信息"
        ;;
    *)
        main
        ;;
esac