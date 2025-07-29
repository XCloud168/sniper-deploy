# Sniper Bot 一键部署系统

这是一个用于本地部署 Sniper Bot 服务的一键部署脚本，支持自动检查Docker环境、验证许可证、下载Docker镜像并启动服务。

## 系统要求

- macOS 或 Linux 系统
- 网络连接（用于下载Docker镜像）
- 有效的许可证文件 (`license.lic`)

## 文件结构

```
deploy/
├── docker-compose.yml    # Docker Compose 配置文件
├── prepare.sh           # Docker 环境检查和安装脚本
├── deploy.sh            # 主部署脚本
├── check_version.sh     # 版本信息检查脚本
├── license.lic          # 许可证文件（用户手动放置）
├── env.example          # 环境变量示例文件
├── config/              # 配置文件目录（自动创建）
├── data/                # 数据目录
├── logs/                # 日志目录
└── README.md           # 本说明文件
```

## 快速开始

### 1. 准备许可证文件

将您的 `license.lic` 文件放置在部署目录中。

### 2. 检查Docker环境

运行以下命令检查并安装Docker：

```bash
chmod +x prepare.sh
./prepare.sh
```

此脚本将：
- 检查Docker是否已安装
- 如果未安装，自动安装Docker
- 启动Docker服务
- 验证Docker环境是否可用

### 3. 配置环境变量（可选）

复制环境变量示例文件并根据需要修改：

```bash
cp env.example .env
# 编辑 .env 文件配置必要的环境变量
```

### 4. 执行部署

运行以下命令开始部署：

```bash
chmod +x deploy.sh
./deploy.sh [版本]  # 部署指定版本，默认为latest
```

**示例：**
```bash
./deploy.sh            # 部署最新版本
./deploy.sh 0.0.1     # 部署0.0.1版本
./deploy.sh latest     # 部署最新版本
```

## 部署流程

部署过程包括以下步骤：

1. **环境检查**
   - 检查许可证文件是否存在
   - 验证Docker环境是否可用
   - 检查必要的配置文件

2. **许可证验证**
   - 发送许可证到服务器进行验证
   - 获取下载配置和下载URL
   - 下载并解压安全文件（public.pem, fernet.key）

3. **镜像下载**
   - 从S3下载Docker镜像文件
   - 验证下载文件的完整性

4. **镜像加载**
   - 将下载的镜像加载到本地Docker环境
   - 验证镜像加载是否成功

5. **数据库迁移**
   - 启动PostgreSQL和Redis服务
   - PostgreSQL启动时自动创建sniper_bot数据库
   - 等待数据库服务就绪
   - 执行Alembic数据库迁移到最新版本

6. **服务管理**
   - 停止现有服务（如果有）
   - 启动新服务
   - 显示服务状态和访问地址

## 脚本功能

### prepare.sh

- 自动检测操作系统（macOS/Linux）
- 检查Docker安装状态
- 自动安装Docker（如果未安装）
- 启动Docker服务
- 验证Docker环境

### deploy.sh

- 环境检查和验证
- 许可证验证和下载配置获取
- 安全文件配置（public.pem, fernet.key）
- Docker镜像下载和加载
- 数据库迁移执行
- 服务管理（启动、停止、重启、状态查看、迁移）

### check_version.sh

- 版本信息检查
- Docker镜像版本查看
- 运行中容器状态检查
- 配置文件版本验证
- 许可证信息检查

## 服务管理

### 命令行参数

```bash
# 完整部署
./deploy.sh [版本]     # 部署指定版本，默认为latest

# 查看服务日志
./deploy.sh logs

# 停止服务
./deploy.sh stop

# 重启服务
./deploy.sh restart

# 查看服务状态
./deploy.sh status

# 执行数据库迁移
./deploy.sh migrate

# 显示帮助信息
./deploy.sh help
```

### 版本检查

```bash
# 完整版本检查
./check_version.sh

# 只检查Docker镜像
./check_version.sh images

# 只检查运行中的容器
./check_version.sh containers

# 只检查配置文件版本
./check_version.sh config

# 只检查许可证信息
./check_version.sh license

# 只检查配置文件
./check_version.sh files

# 显示版本检查帮助
./check_version.sh help
```

## 服务架构

部署后，系统包含以下服务：

- **数据库迁移服务** (`db-migrate`): 执行Alembic数据库迁移（一次性服务）
- **API服务** (`sniper-api`): 后端API服务，端口8000
- **前端服务** (`sniper-frontend`): Web前端界面，端口3000

## 服务访问地址

部署成功后，可以通过以下地址访问服务：

- http://localhost:9000

## 配置说明

### 环境变量

创建 `.env` 文件配置服务环境变量，参考 `env.example` 文件：

```bash
# 数据库配置
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=sniper_bot
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# 加密密钥
ENCRYPTION_KEY=your-encryption-key

# 其他配置...
```

## 故障排除

### 常见问题

1. **Docker未安装**
   ```bash
   ./prepare.sh
   ```

2. **许可证验证失败**
   - 检查 `license.lic` 文件是否存在
   - 确认许可证内容正确
   - 检查网络连接
   - 脚本会自动显示服务端返回的错误信息

3. **下载包验证失败**
   - 脚本会检查下载的文件是否为有效的tar.gz格式
   - 如果服务端返回JSON错误信息，脚本会显示具体错误内容
   - 检查许可证是否有效或版本是否正确

4. **镜像下载失败**
   - 检查网络连接
   - 确认S3 URL配置正确
   - 检查许可证是否有效

5. **数据库迁移失败**
   ```bash
   # 手动执行迁移
   ./deploy.sh migrate

   # 查看迁移日志
   docker-compose logs db-migrate

   # 检查数据库连接
   docker-compose exec postgres psql -U postgres -d sniper_bot -c "\l"
   ```

6. **前端权限错误**
   ```bash
   # 查看前端日志
   docker-compose logs frontend

   # 重启前端服务
   docker-compose restart frontend

   # 清理前端缓存
   docker-compose down
   docker volume rm deploy_frontend_cache
   docker-compose up -d
   ```

7. **服务启动失败**
   ```bash
   # 查看服务日志
   ./deploy.sh logs

   # 查看详细错误信息
   docker-compose logs
   ```

### 日志查看

```bash
# 查看所有服务日志
./deploy.sh logs

# 查看特定服务日志
docker-compose logs [service-name]

# 实时查看日志
docker-compose logs -f [service-name]
```

### 服务管理

```bash
# 停止所有服务
./deploy.sh stop

# 重启所有服务
./deploy.sh restart

# 查看服务状态
./deploy.sh status

# 执行数据库迁移
./deploy.sh migrate

# 使用docker-compose命令
docker-compose down          # 停止服务
docker-compose up -d        # 启动服务
docker-compose restart      # 重启服务
docker-compose run --rm db-migrate  # 执行迁移
```

## 安全注意事项

1. 确保 `license.lic` 文件安全存储
2. 不要将许可证文件提交到版本控制系统
3. 定期更新许可证
4. 监控服务运行状态
5. 保护 `.env` 文件中的敏感信息

## 更新说明

当有新版本发布时：

1. 更新 `license.lic` 文件（如果需要）
2. 运行 `./deploy.sh [新版本]` 重新部署
3. 脚本会自动下载新版本的Docker镜像

## 技术支持

如果遇到问题，请：

1. 查看服务日志：`./deploy.sh logs`
2. 检查Docker状态：`docker info`
3. 验证网络连接
4. 运行版本检查：`./check_version.sh`
5. 查看数据库迁移指南：`MIGRATION_GUIDE.md`
6. 联系技术支持团队

---

**注意**: 请确保在运行脚本前已正确配置所有必要的环境变量和许可证文件。