# Sniper Bot 部署指南

本指南将帮助您完成 Sniper Bot 系统的完整部署流程。

## 目录

- [系统要求](#系统要求)
- [预部署准备](#预部署准备)
- [部署步骤](#部署步骤)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [故障排除](#故障排除)
- [维护指南](#维护指南)

## 系统要求

### 硬件要求

- **CPU**: 至少 2 核心处理器
- **内存**: 至少 4GB RAM（推荐 8GB 或更多）
- **存储**: 至少 20GB 可用磁盘空间
- **网络**: 稳定的互联网连接

### 软件要求

- **操作系统**: macOS 10.15+ 或 Linux (Ubuntu 18.04+, CentOS 7+)
- **Docker**: 20.10+ 版本
- **Docker Compose**: 2.0+ 版本
- **网络**: 能够访问外部 API 服务

## 预部署准备

### 1. 获取许可证文件

确保您拥有有效的 `license.lic` 文件。将此文件放置在部署目录中。

### 2. 检查系统环境

在开始部署前，请确认：

- 系统已连接到互联网
- 有足够的磁盘空间
- 端口 3000, 8000, 5678, 5432, 6379 未被占用

### 3. 准备环境变量

复制环境变量示例文件：

```bash
cp env.example .env
```

编辑 `.env` 文件，配置必要的环境变量（详见[配置说明](#配置说明)部分）。

## 部署步骤

### 步骤 1: 环境检查

运行环境检查脚本：

```bash
chmod +x prepare.sh
./prepare.sh
```

此脚本将：
- 检查 Docker 是否已安装
- 如果未安装，自动安装 Docker
- 启动 Docker 服务
- 验证 Docker 环境是否可用

**预期输出**：
```
=== Docker 环境检查与安装脚本 ===
检测到 macOS 系统
✓ Docker 已安装
✓ Docker 服务正在运行
✓ Docker 环境检查完成，可以开始部署
```

### 步骤 2: 执行部署

运行部署脚本：

```bash
chmod +x deploy.sh
./deploy.sh [版本]
```

**参数说明**：
- `[版本]`: 可选参数，指定部署版本（默认为 `latest`）

**示例**：
```bash
./deploy.sh          # 部署最新版本
./deploy.sh 0.0.1    # 部署 0.0.1 版本
./deploy.sh latest    # 部署最新版本
```

### 步骤 3: 验证部署

部署完成后，验证服务状态：

```bash
./deploy.sh status
```

**预期输出**：
```
Name                    Command               State           Ports
--------------------------------------------------------------------------------
deploy_api_1           uv run app/api/server.py    Up      0.0.0.0:8000->8000/tcp
deploy_frontend_1      npm start                   Up      0.0.0.0:3000->3000/tcp
deploy_n8n_1           tini -- /usr/local/bin/...  Up      0.0.0.0:5678->5678/tcp
deploy_postgres_1      docker-entrypoint.sh postgres Up      0.0.0.0:5432->5432/tcp
deploy_redis_1         docker-entrypoint.sh redis... Up      0.0.0.0:6379->6379/tcp
```

### 步骤 4: 访问服务

部署成功后，可以通过以下地址访问服务：

- **前端界面**: http://localhost:3000
- **API 服务**: http://localhost:8000
- **n8n 工作流**: http://localhost:5678

## 配置说明

### 环境变量配置

编辑 `.env` 文件，配置以下关键参数：

#### 数据库配置
```bash
# PostgreSQL 数据库配置
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=sniper_bot
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

#### API 密钥配置
```bash
# Helius API 密钥（Solana 区块链）
HELIUS_API_KEY=your-helius-api-key
HELIUS_API_BASE_URL=https://api.helius.xyz/v0/

# Alchemy API 密钥（以太坊区块链）
ALCHEMY_API_KEY=your-alchemy-api-key

# Shyft API 密钥
SHYFT_API_KEY=your-shyft-api-key
```

#### 加密配置
```bash
# 加密密钥
ENCRYPTION_KEY=your-encryption-key

# JWT 认证密钥
SECRET_KEY=your-secret-key-for-jwt
```

#### Webhook 配置
```bash
# Webhook URL
WEBHOOK_URL=https://your-domain.com
```

### 网络配置

确保以下端口可用：

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端 | 3000 | Web 界面 |
| API | 8000 | 后端 API |

## 服务管理

### 查看服务状态

```bash
# 查看所有服务状态
./deploy.sh status

# 查看特定服务状态
docker-compose ps [service-name]
```

### 查看服务日志

```bash
# 查看所有服务日志
./deploy.sh logs

# 查看特定服务日志
docker-compose logs [service-name]

# 实时查看日志
docker-compose logs -f [service-name]
```

### 服务控制

```bash
# 停止所有服务
./deploy.sh stop

# 重启所有服务
./deploy.sh restart

# 使用 docker-compose 命令
docker-compose down          # 停止服务
docker-compose up -d        # 启动服务
docker-compose restart      # 重启服务
```

### 版本管理

```bash
# 检查当前版本
./check_version.sh

# 检查 Docker 镜像版本
./check_version.sh images

# 检查运行中的容器
./check_version.sh containers

# 检查配置文件版本
./check_version.sh config
```

## 故障排除

### 常见问题及解决方案

#### 1. Docker 未安装或服务未启动

**症状**: 运行 `./prepare.sh` 时提示 Docker 未安装或服务未运行

**解决方案**:
```bash
# 运行环境检查脚本
./prepare.sh

# 如果脚本无法自动安装，手动安装 Docker
# macOS: 下载并安装 Docker Desktop
# Linux: 使用包管理器安装 Docker
```

#### 2. 许可证验证失败

**症状**: 部署时提示许可证验证失败

**解决方案**:
1. 检查 `license.lic` 文件是否存在
2. 确认许可证内容正确
3. 检查网络连接
4. 联系技术支持获取有效许可证

#### 3. 镜像下载失败

**症状**: 下载 Docker 镜像时失败

**解决方案**:
1. 检查网络连接
2. 确认防火墙设置
3. 检查磁盘空间
4. 重试下载命令

#### 4. 服务启动失败

**症状**: 服务启动后立即停止

**解决方案**:
```bash
# 查看详细错误日志
./deploy.sh logs

# 检查环境变量配置
cat .env

# 检查端口占用
netstat -tulpn | grep :3000
netstat -tulpn | grep :8000
```

#### 5. 数据库连接失败

**症状**: API 服务无法连接到数据库

**解决方案**:
1. 检查 PostgreSQL 服务状态
2. 验证数据库配置
3. 检查网络连接
4. 重启数据库服务

### 日志分析

#### 查看错误日志

```bash
# 查看所有服务的错误日志
docker-compose logs --tail=100 | grep ERROR

# 查看特定服务的错误日志
docker-compose logs api | grep ERROR
docker-compose logs frontend | grep ERROR
```

#### 常见错误信息

1. **Connection refused**: 服务间网络连接问题
2. **Permission denied**: 文件权限问题
3. **Port already in use**: 端口被占用
4. **Out of memory**: 内存不足
5. **Disk space full**: 磁盘空间不足

### 性能优化

#### 系统资源监控

```bash
# 查看容器资源使用情况
docker stats

# 查看系统资源使用情况
top
htop
```

#### 优化建议

1. **内存优化**: 确保系统有足够内存（推荐 8GB+）
2. **存储优化**: 定期清理日志文件
3. **网络优化**: 确保网络连接稳定
4. **CPU 优化**: 避免在部署期间运行其他重负载程序

## 维护指南

### 日常维护

#### 1. 日志管理

```bash
# 查看日志文件大小
du -sh logs/*

# 清理旧日志
find logs/ -name "*.log" -mtime +7 -delete
```

#### 2. 数据备份

```bash
# 备份数据库
docker-compose exec postgres pg_dump -U postgres sniper_bot > backup.sql

# 备份配置文件
tar -czf config_backup.tar.gz config/
```

#### 3. 版本更新

```bash
# 更新到新版本
./deploy.sh [新版本号]

# 验证更新
./check_version.sh
```

### 监控和告警

#### 服务健康检查

```bash
# 检查服务健康状态
curl -f http://localhost:8000/ping
curl -f http://localhost:3000
curl -f http://localhost:5678
```

#### 自动化监控脚本

创建监控脚本 `monitor.sh`:

```bash
#!/bin/bash

# 检查服务状态
if ! docker-compose ps | grep -q "Up"; then
    echo "警告: 有服务未正常运行"
    docker-compose ps
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
```

### 安全建议

1. **定期更新**: 及时更新系统和 Docker 镜像
2. **访问控制**: 限制对管理端口的访问
3. **日志监控**: 定期检查日志文件
4. **备份策略**: 定期备份重要数据
5. **网络安全**: 使用防火墙保护服务

## 技术支持

如果遇到无法解决的问题，请：

1. 收集错误日志和系统信息
2. 运行诊断命令：`./check_version.sh`
3. 记录详细的错误步骤
4. 联系技术支持团队并提供相关信息

### 有用的诊断命令

```bash
# 系统信息
uname -a
docker --version
docker-compose --version

# 服务状态
./deploy.sh status
./check_version.sh

# 网络连接
ping google.com
curl -I http://localhost:8000

# 磁盘空间
df -h
du -sh *
```

---

**注意**: 本指南基于当前版本编写，如有更新请参考最新的文档。