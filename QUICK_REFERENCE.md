# Sniper Bot 快速参考

## 🚀 快速部署

### 一键部署

```bash
# 环境检查
./prepare.sh

# 安装并启动服务
./setup.sh
```

### 服务管理

```bash
# 查看状态
docker compose ps

# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看日志
docker compose logs -f
```

## 📋 常用命令

### 版本检查

```bash
# 查看 Docker 镜像
docker images

# 查看运行中的容器
docker compose ps

# 查看服务状态
docker compose ps

# 查看版本信息
docker compose exec api python -c "import app; print(app.__version__)" 2>/dev/null || echo "版本信息不可用"
```

### Docker 命令

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs [service]

# 重启服务
docker compose restart [service]

# 进入容器
docker compose exec [service] bash
```

### 数据库操作

```bash
# 执行迁移
docker compose run --rm db-migrate

# 备份数据库
docker compose exec postgres pg_dump -U postgres sniper_bot > backup.sql

# 恢复数据库
docker compose exec -T postgres psql -U postgres sniper_bot < backup.sql
```

## ⚙️ 配置参考

### 环境变量

```bash
# 复制配置模板
cp env.example .env

# 编辑配置
vim .env

# 主要配置项
# - DATABASE_URL: 数据库连接
# - REDIS_URL: Redis 连接
# - SECRET_KEY: JWT 认证密钥
# - OKX_API_*: OKX API 凭据
# - CHAINS__*__RPC_URL: 区块链 RPC 配置
# - SIGNAL_*: Signal 配置
# - DEFAULT_ADMIN_*: 默认管理员账户
```

### 端口配置

| 服务       | 端口 | 说明     |
| ---------- | ---- | -------- |
| 前端       | 9000 | Web 界面 |
| API        | 8000 | 后端 API |
| PostgreSQL | 5432 | 数据库   |
| Redis      | 6379 | 缓存     |

### 服务器配置

```bash
# 使用服务器配置
cp env.server.example .env
cp docker-compose-server.yml docker-compose.yml
cp nginx/nginx-server.conf nginx/nginx.conf
```

## 🔍 故障排除

### 常见问题

```bash
# Docker 未启动
./prepare.sh

# 端口被占用
sudo lsof -ti:9000 | xargs kill -9

# 查看错误日志
docker compose logs | grep ERROR

# 清理系统
docker system prune -f
```

### 诊断命令

```bash
# 系统信息
uname -a
docker --version

# 网络测试
curl -f http://localhost:9000

# 磁盘空间
df -h
du -sh *
```

## 📦 发布管理

### 创建发布

```bash
# 提交代码
git add .
git commit -m "准备发布"
git push origin main

# 创建 tag
git tag v1.0.0
git push origin v1.0.0
```

### 下载发布包

- 访问 GitHub Releases 页面
- 下载 `masbate-deploy-{version}.tar.gz` 或 `.zip`
- 解压到本地目录

## 🔧 维护命令

### 备份

```bash
# 备份数据库
docker compose exec postgres pg_dump -U postgres sniper_bot > backup_$(date +%Y%m%d).sql

# 备份配置
tar -czf config_backup_$(date +%Y%m%d).tar.gz config/
```

### 清理

```bash
# 清理日志
find logs/ -name "*.log" -mtime +7 -delete

# 清理 Docker
docker system prune -f
docker volume prune -f
```

### 监控

```bash
# 资源使用
docker stats

# 健康检查
curl -f http://localhost:9000
```

## 📞 支持

### 获取帮助

```bash
# 查看帮助
./setup.sh help

# 运行诊断
docker compose ps
docker images
```

### 日志位置

- 应用日志: `logs/`
- Docker 日志: `docker compose logs`
- 系统日志: `/var/log/`

---

**提示**: 更多详细信息请参考 [README.md](README.md)
