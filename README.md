# Sniper Bot 一键部署系统

一个完整的 Sniper Bot 自动化部署解决方案，支持本地部署、服务器部署和自动发布管理。

## 📋 目录

- [系统概述](#系统概述)
- [快速开始](#快速开始)
- [部署指南](#部署指南)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [自动发布](#自动发布)
- [故障排除](#故障排除)
- [维护指南](#维护指南)

## 🚀 系统概述

Sniper Bot 部署系统提供：

- ✅ **一键部署**: 自动化环境检查和部署流程
- ✅ **多环境支持**: 本地开发和生产服务器部署
- ✅ **自动发布**: GitHub Actions 自动发布管理
- ✅ **完整监控**: 服务状态检查和日志管理
- ✅ **安全配置**: 许可证验证和加密管理

### 系统架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端服务      │    │   API 服务      │    │   数据库服务    │
│   (Port 3000)   │    │   (Port 8000)   │    │   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Redis 缓存    │
                    │   (Port 6379)   │
                    └─────────────────┘
```

## ⚡ 快速开始

### 系统要求

- **操作系统**: macOS 10.15+ 或 Linux (Ubuntu 18.04+, CentOS 7+)
- **硬件**: 2 核心 CPU, 4GB RAM (推荐 8GB+), 20GB 磁盘空间
- **网络**: 稳定的互联网连接
- **端口**: 3000, 8000, 5432, 6379 未被占用

### 1. 获取部署包

#### 方式一：从 GitHub Release 下载

1. 访问 [GitHub Releases](https://github.com/XCloud168/releases)
2. 下载最新版本的 `masbate-deploy-{version}.tar.gz` 或 `masbate-deploy-{version}.zip`
3. 解压到本地目录

#### 方式二：从源码构建

```bash
git clone https://github.com/XCloud168/deploy.git
cd deploy
```

### 2. 准备许可证文件

将您的 `license.lic` 文件放置在部署目录中。

### 3. 环境检查

```bash
chmod +x prepare.sh
./prepare.sh
```

### 4. 执行部署

```bash
chmod +x setup.sh
./setup.sh  # 安装并启动 Sniper Bot
```

### 5. 验证部署

```bash
docker compose ps
```

访问 http://localhost:9000 查看前端界面。

## 📖 部署指南

### 本地部署

#### 步骤 1: 环境准备

1. **检查系统环境**

   ```bash
   # 检查操作系统
   uname -s

   # 检查可用端口
   netstat -tulpn | grep :9000
   ```

2. **准备许可证文件**

   - 将 `license.lic` 文件放置在部署目录
   - 确保文件权限正确：`chmod 600 license.lic`

3. **配置环境变量**
   ```bash
   cp env.example .env
   # 编辑 .env 文件配置必要的环境变量
   # 主要配置项包括：
   # - OKX API 凭据 (OKX_API_KEY, OKX_SECRET_KEY 等)
   # - 区块链 RPC 配置 (CHAINS__*__RPC_URL)
   # - Signal 配置 (SIGNAL_*)
   # - 默认管理员账户 (DEFAULT_ADMIN_*)
   ```

#### 步骤 2: Docker 环境

```bash
# 运行环境检查脚本
./prepare.sh
```

**预期输出**：

```
=== Docker 环境检查与安装脚本 ===
检测到 macOS 系统
✓ Docker 已安装
✓ Docker 服务正在运行
✓ Docker 环境检查完成，可以开始部署
```

#### 步骤 3: 执行部署

```bash
# 安装并启动服务
./setup.sh

# 查看服务状态
docker compose ps

# 查看部署进度
docker compose logs -f
```

#### 步骤 4: 验证服务

```bash
# 检查服务状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 测试服务连接
curl -f http://localhost:9000
```

## ⚙️ 配置说明

### 环境变量配置

#### 基础配置

```bash
# 开发模式
DEV_MODE=false

# 数据库连接
DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/sniper_bot

# Redis 连接
REDIS_URL=redis://redis:6379/0

# JWT 认证密钥
SECRET_KEY=your-secret-key-for-jwt

# 日志级别
LOG_LEVEL=INFO

# 测试模式
TEST_MODE=false

# HTTP 代理 (可选)
# HTTP_PROXY=http://127.0.0.1:7897
```

#### OKX DEX RPC 配置

```bash
# OKX API 凭据
OKX_API_KEY=your-okx-api-key
OKX_SECRET_KEY=your-okx-secret-key
OKX_API_PASSPHRASE=your-okx-passphrase
OKX_PROJECT_ID=your-okx-project-id

# 区块链 RPC 配置
# 以太坊主网
CHAINS__1__RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-alchemy-key

# BNB 主网
CHAINS__56__RPC_URL=https://bnb-mainnet.g.alchemy.com/v2/your-alchemy-key

# Solana 主网
CHAINS__501__RPC_URL=https://solana-mainnet.g.alchemy.com/v2/your-alchemy-key
```

#### Signal 配置

```bash
# Signal 频道
SIGNAL_CHANNEL=signals:projects

# Signal 订阅 URL
SIGNAL_SUBSCRIBE_URL=wss://my.trustcoin.com/connection/websocket

# Signal API Token URL
SIGNAL_API_TOKEN_URL=https://xmsbatedys.masbate.xyz/get-subscription-token
```

#### 默认管理员用户配置

```bash
# 默认管理员用户名
DEFAULT_ADMIN_USERNAME=admin

# 默认管理员邮箱
DEFAULT_ADMIN_EMAIL=admin@sniper-bot.com

# 默认管理员密码
DEFAULT_ADMIN_PASSWORD=admin123456

# 版本号
VERSION=0.0.8
```

### 网络配置

| 服务       | 端口 | 说明     | 外部访问    |
| ---------- | ---- | -------- | ----------- |
| Nginx      | 9000 | Web 界面 | ✅          |
| PostgreSQL | 5432 | 数据库   | ❌ (仅内部) |
| Redis      | 6379 | 缓存     | ❌ (仅内部) |

### 安全配置

1. **防火墙设置**

   ```bash
   # 只开放必要端口
   sudo ufw enable
   ```

2. **SSL 证书配置**
   ```bash
   # 配置 Nginx SSL
   ssl_certificate /path/to/your/certificate.crt;
   ssl_certificate_key /path/to/your/private.key;
   ```

## 🔧 服务管理

### 服务控制命令

```bash
# 查看服务状态
docker compose ps

# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看日志
docker compose logs -f

# 执行数据库迁移
docker compose run --rm db-migrate
```

### 日志管理

```bash
# 查看特定服务日志
docker compose logs [service-name]

# 实时查看日志
docker compose logs -f [service-name]

# 查看错误日志
docker compose logs | grep ERROR
```

## 🚀 自动发布

### GitHub Actions 自动发布

项目配置了自动发布工作流，当创建新的 tag 时会自动生成 release 并提供过滤后的压缩包下载。

#### 工作原理

1. **触发条件**: 推送以 `v` 开头的 tag (如 `v1.0.0`)
2. **过滤规则**: 自动排除服务器特定配置文件
3. **生成文件**:
   - `masbate-deploy-{version}.tar.gz` - Gzip 压缩包
   - `masbate-deploy-{version}.zip` - ZIP 压缩包

#### 排除的文件和目录

- `centrifugo/` - Centrifugo 配置目录
- `docker-compose-server.yml` - 服务器版 Docker Compose 配置
- `nginx/nginx-server.conf` - 服务器版 Nginx 配置
- `env.server.example` - 服务器版环境变量示例
- `.git/` - Git 版本控制目录
- `temp_downloads/` - 临时下载目录
- `logs/` - 日志目录
- `data/` - 数据目录

#### 使用方法

1. **准备发布**

   ```bash
   git add .
   git commit -m "准备发布新版本"
   git push origin main
   ```

2. **创建发布 tag**

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **自动发布**

   - GitHub Actions 自动检测 tag
   - 过滤文件并生成压缩包
   - 创建 GitHub Release 并上传文件

4. **查看结果**
   - 访问 GitHub 仓库的 "Releases" 页面
   - 下载生成的压缩包

### 版本命名规范

建议使用语义化版本号：

- `v1.0.0` - 主版本.次版本.修订版本
- `v1.1.0` - 新功能发布
- `v1.0.1` - 错误修复
- `v2.0.0` - 重大更新（可能不兼容）

## 🔍 故障排除

### 常见问题

#### 1. Docker 环境问题

**症状**: Docker 未安装或服务未启动

**解决方案**:

```bash
# 运行环境检查脚本
./prepare.sh

# 手动启动 Docker
# macOS: 启动 Docker Desktop
# Linux: sudo systemctl start docker
```

#### 2. 许可证验证失败

**症状**: 部署时提示许可证验证失败

**解决方案**:

1. 检查 `license.lic` 文件是否存在
2. 确认许可证内容正确
3. 检查网络连接
4. 联系技术支持获取有效许可证

#### 3. 端口冲突

**症状**: 服务启动失败，提示端口被占用

**解决方案**:

```bash
# 检查端口占用
netstat -tulpn | grep :3000
netstat -tulpn | grep :8000

# 停止占用端口的进程
sudo lsof -ti:3000 | xargs kill -9
sudo lsof -ti:8000 | xargs kill -9
```

#### 4. 数据库连接失败

**症状**: API 服务无法连接到数据库

**解决方案**:

```bash
# 检查数据库服务状态
docker compose ps postgres

# 重启数据库服务
docker compose restart postgres

# 检查数据库日志
docker compose logs postgres
```

#### 5. 内存不足

**症状**: 服务启动后立即停止

**解决方案**:

```bash
# 检查系统内存
free -h

# 增加 Docker 内存限制
# macOS: Docker Desktop -> Settings -> Resources
# Linux: 编辑 /etc/docker/daemon.json
```

### 诊断命令

```bash
# 系统信息
uname -a
   docker --version
   docker compose --version

# 服务状态
docker compose ps

# 网络连接
ping google.com
curl -I http://localhost:8000

# 磁盘空间
df -h
du -sh *

# 内存使用
free -h
top
```

### 日志分析

```bash
# 查看错误日志
docker compose logs --tail=100 | grep ERROR

# 查看特定服务错误
docker compose logs api | grep ERROR
docker compose logs frontend | grep ERROR

# 实时监控日志
docker compose logs -f --tail=50
```

## 🛠️ 维护指南

### 日常维护

#### 1. 日志管理

```bash
# 查看日志文件大小
du -sh logs/*

# 清理旧日志
find logs/ -name "*.log" -mtime +7 -delete

# 压缩日志文件
gzip logs/*.log
```

#### 2. 数据备份

```bash
# 备份数据库
docker compose exec postgres pg_dump -U postgres sniper_bot > backup_$(date +%Y%m%d).sql

# 备份配置文件
tar -czf config_backup_$(date +%Y%m%d).tar.gz config/

# 备份整个数据目录
tar -czf data_backup_$(date +%Y%m%d).tar.gz data/
```

#### 3. 版本更新

```bash
# 更新到新版本
./setup.sh


# 重新部署（如果需要）
./setup.sh
```

### 性能监控

#### 系统资源监控

```bash
# 查看容器资源使用情况
docker stats

# 查看系统资源使用情况
htop
iotop
```

#### 服务健康检查

```bash
# 创建健康检查脚本
cat > health_check.sh << 'EOF'
#!/bin/bash

# 检查服务状态
if ! docker compose ps | grep -q "Up"; then
    echo "警告: 有服务未正常运行"
    docker compose ps
    exit 1
fi

# 检查磁盘空间
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "警告: 磁盘使用率超过 80%"
fi

# 检查内存使用
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ $MEM_USAGE -gt 80 ]; then
    echo "警告: 内存使用率超过 80%"
fi

echo "系统健康检查完成"
EOF

chmod +x health_check.sh
```

### 安全维护

1. **定期更新**

   - 及时更新系统和 Docker 镜像
   - 定期检查安全补丁

2. **访问控制**

   - 限制对管理端口的访问
   - 使用强密码和密钥

3. **监控告警**

   - 设置日志监控
   - 配置异常告警

4. **备份策略**
   - 定期备份重要数据
   - 测试备份恢复流程

## 📞 技术支持

### 获取帮助

如果遇到问题，请按以下步骤操作：

1. **收集信息**

   ```bash
   # 收集系统信息
   uname -a
   docker --version
   docker compose --version
   ```

2. **查看日志**

   ```bash
   # 查看错误日志
   docker compose logs | grep ERROR

   # 查看特定服务日志
   docker compose logs [service-name]
   ```

3. **联系支持**

- 提供详细的错误信息
- 包含系统环境和配置信息
- 描述问题发生的具体步骤

### 有用的命令

```bash
# 完整系统检查
docker compose ps
docker images
docker system df

# 服务状态检查
docker compose ps

# 网络连接测试
curl -f http://localhost:9000

# 数据库连接测试
docker compose exec postgres psql -U postgres -d sniper_bot -c "SELECT version();"

# 清理系统
docker system prune -f
docker volume prune -f
```

---

**注意**: 本指南基于当前版本编写，如有更新请参考最新的文档。确保在运行脚本前已正确配置所有必要的环境变量和许可证文件。
