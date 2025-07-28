# Sniper Bot 快速参考

## 🚀 快速开始

### 首次部署
```bash
# 1. 环境检查
./prepare.sh

# 2. 配置环境变量
cp env.example .env
# 编辑 .env 文件

# 3. 部署服务
./deploy.sh [版本]
```

### 常用命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `./deploy.sh` | 部署最新版本 | `./deploy.sh` |
| `./deploy.sh [版本]` | 部署指定版本 | `./deploy.sh 0.0.1` |
| `./deploy.sh status` | 查看服务状态 | `./deploy.sh status` |
| `./deploy.sh logs` | 查看服务日志 | `./deploy.sh logs` |
| `./deploy.sh stop` | 停止所有服务 | `./deploy.sh stop` |
| `./deploy.sh restart` | 重启所有服务 | `./deploy.sh restart` |
| `./deploy.sh help` | 显示帮助信息 | `./deploy.sh help` |

## 📊 监控和诊断

### 版本检查
```bash
# 完整版本检查
./check_version.sh

# 检查 Docker 镜像
./check_version.sh images

# 检查运行中的容器
./check_version.sh containers

# 检查配置文件
./check_version.sh config
```

### 服务状态
```bash
# 查看所有服务状态
docker-compose ps

# 查看特定服务状态
docker-compose ps api
docker-compose ps frontend
docker-compose ps n8n
```

### 日志查看
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs api
docker-compose logs frontend
docker-compose logs n8n

# 实时查看日志
docker-compose logs -f api
```

## 🔧 故障排除

### 常见问题解决

| 问题 | 解决方案 |
|------|----------|
| Docker 未安装 | `./prepare.sh` |
| 许可证验证失败 | 检查 `license.lic` 文件 |
| 服务启动失败 | `./deploy.sh logs` 查看错误 |
| 端口被占用 | 检查端口 3000, 8000, 5678 |
| 磁盘空间不足 | `df -h` 检查磁盘使用 |

### 诊断命令
```bash
# 系统信息
uname -a
docker --version

# 网络连接
ping google.com
curl -I http://localhost:8000

# 资源使用
docker stats
df -h
free -h
```

## 🌐 服务访问

| 服务 | 地址 | 端口 |
|------|------|------|
| 前端界面 | http://localhost:3000 | 3000 |
| API 服务 | http://localhost:8000 | 8000 |

## 📁 文件结构

```
deploy/
├── docker-compose.yml    # Docker 配置
├── deploy.sh            # 主部署脚本
├── prepare.sh           # 环境检查脚本
├── check_version.sh     # 版本检查脚本
├── license.lic          # 许可证文件
├── env.example          # 环境变量示例
├── .env                 # 环境变量配置
├── config/              # 配置文件目录
├── data/                # 数据目录
└── logs/                # 日志目录
```

## ⚙️ 配置说明

### 关键环境变量
```bash
# 数据库配置
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=sniper_bot
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# 加密配置
ENCRYPTION_KEY=your-encryption-key
SECRET_KEY=your-secret-key-for-jwt

```

## 🔄 维护操作

### 数据备份
```bash
# 备份数据库
docker-compose exec postgres pg_dump -U postgres sniper_bot > backup.sql

# 备份配置文件
tar -czf config_backup.tar.gz config/
```

### 版本更新
```bash
# 更新到新版本
./deploy.sh [新版本号]

# 验证更新
./check_version.sh
```

### 日志管理
```bash
# 查看日志大小
du -sh logs/*

# 清理旧日志
find logs/ -name "*.log" -mtime +7 -delete
```

## 🛡️ 安全建议

1. **定期更新**: 及时更新系统和 Docker 镜像
2. **访问控制**: 限制对管理端口的访问
3. **日志监控**: 定期检查日志文件
4. **备份策略**: 定期备份重要数据
5. **网络安全**: 使用防火墙保护服务

## 📞 技术支持

遇到问题时：

1. 运行诊断命令：`./check_version.sh`
2. 查看错误日志：`./deploy.sh logs`
3. 收集系统信息：`uname -a; docker --version`
4. 联系技术支持团队

---

**提示**: 使用 `./deploy.sh help` 查看完整的命令帮助信息。