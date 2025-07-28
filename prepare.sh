#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Docker 环境检查与安装脚本 ===${NC}"

# 检查是否为root用户
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}错误: 请不要使用root用户运行此脚本${NC}"
   exit 1
fi

# 检查Docker是否已安装
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker 已安装${NC}"
        docker --version
        return 0
    else
        echo -e "${YELLOW}✗ Docker 未安装${NC}"
        return 1
    fi
}

# 检查Docker服务是否运行
check_docker_service() {
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓ Docker 服务正在运行${NC}"
        return 0
    else
        echo -e "${YELLOW}✗ Docker 服务未运行${NC}"
        return 1
    fi
}

# 安装Docker (macOS)
install_docker_macos() {
    echo -e "${YELLOW}正在安装 Docker Desktop for macOS...${NC}"

    # 检查是否已安装Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}正在安装 Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 安装Docker Desktop
    brew install --cask docker

    echo -e "${GREEN}Docker Desktop 安装完成${NC}"
    echo -e "${YELLOW}请启动 Docker Desktop 应用程序${NC}"
    echo -e "${YELLOW}启动后请重新运行此脚本${NC}"
    exit 0
}

# 安装Docker (Linux)
install_docker_linux() {
    echo -e "${YELLOW}正在安装 Docker...${NC}"

    # 更新包索引
    sudo apt-get update

    # 安装必要的包
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # 设置稳定版仓库
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER

    echo -e "${GREEN}Docker 安装完成${NC}"
    echo -e "${YELLOW}请注销并重新登录，或运行: newgrp docker${NC}"
    echo -e "${YELLOW}然后重新运行此脚本${NC}"
    exit 0
}

# 启动Docker服务 (Linux)
start_docker_service() {
    echo -e "${YELLOW}正在启动 Docker 服务...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker

    # 等待服务启动
    sleep 5

    if check_docker_service; then
        echo -e "${GREEN}✓ Docker 服务启动成功${NC}"
    else
        echo -e "${RED}✗ Docker 服务启动失败${NC}"
        exit 1
    fi
}

# 主函数
main() {
    echo -e "${GREEN}开始检查 Docker 环境...${NC}"

    # 检查操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}检测到 macOS 系统${NC}"
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${GREEN}检测到 Linux 系统${NC}"
        OS="linux"
    else
        echo -e "${RED}不支持的操作系统: $OSTYPE${NC}"
        exit 1
    fi

    # 检查Docker是否已安装
    if check_docker; then
        # Docker已安装，检查服务状态
        if check_docker_service; then
            echo -e "${GREEN}✓ Docker 环境检查完成，可以开始部署${NC}"
            exit 0
        else
            if [[ "$OS" == "linux" ]]; then
                start_docker_service
            else
                echo -e "${YELLOW}请启动 Docker Desktop 应用程序${NC}"
                exit 1
            fi
        fi
    else
        # Docker未安装，进行安装
        if [[ "$OS" == "macos" ]]; then
            install_docker_macos
        elif [[ "$OS" == "linux" ]]; then
            install_docker_linux
        fi
    fi
}

# 运行主函数
main