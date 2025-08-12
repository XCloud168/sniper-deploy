# 自动发布指南

## 概述

本项目配置了 GitHub Actions 自动发布工作流，当创建新的 tag 时会自动生成 release 并提供过滤后的压缩包下载。

## 工作原理

1. **触发条件**: 当推送以 `v` 开头的 tag 时（如 `v1.0.0`）
2. **过滤规则**: 自动排除以下文件和目录：

   - `centrifugo/` - Centrifugo 配置目录
   - `docker-compose-server.yml` - 服务器版 Docker Compose 配置
   - `nginx/nginx-server.conf` - 服务器版 Nginx 配置
   - `env.server.example` - 服务器版环境变量示例
   - `.git/` - Git 版本控制目录
   - `temp_downloads/` - 临时下载目录
   - `logs/` - 日志目录
   - `data/` - 数据目录

3. **生成文件**:
   - `masbate-deploy-{version}.tar.gz` - Gzip 压缩包
   - `masbate-deploy-{version}.zip` - ZIP 压缩包

## 使用方法

### 创建新版本发布

1. **确保代码已提交并推送到主分支**

   ```bash
   git add .
   git commit -m "准备发布新版本"
   git push origin main
   ```

2. **创建并推送 tag**

   ```bash
   # 创建本地tag
   git tag v1.0.0

   # 推送tag到远程仓库
   git push origin v1.0.0
   ```

3. **自动触发发布流程**
   - GitHub Actions 会自动检测到新的 tag
   - 创建工作流会过滤文件并生成压缩包
   - 自动创建 GitHub Release 并上传压缩包

### 查看发布结果

1. 访问 GitHub 仓库的 "Releases" 页面
2. 找到对应的版本发布
3. 下载 `masbate-deploy-{version}.tar.gz` 或 `masbate-deploy-{version}.zip`

## 文件结构说明

### 包含在发布包中的文件

- 所有源代码文件
- 配置文件（除了服务器特定配置）
- 文档文件
- 脚本文件

### 排除的文件和目录

- `centrifugo/` - 服务器特定的 Centrifugo 配置
- `docker-compose-server.yml` - 服务器部署配置
- `nginx/nginx-server.conf` - 服务器 Nginx 配置
- `env.server.example` - 服务器环境变量示例
- 临时文件和日志目录

## 故障排除

### 工作流未触发

- 确保 tag 格式正确（以 `v` 开头）
- 检查 GitHub Actions 权限设置
- 查看 Actions 页面确认工作流状态

### 压缩包内容不完整

- 检查 `.gitignore` 文件是否排除了必要文件
- 确认过滤规则是否正确

### 权限问题

- 确保仓库有适当的权限设置
- 检查 GitHub Token 是否有效

## 自定义配置

如需修改过滤规则，编辑 `.github/workflows/release.yml` 文件中的 `rsync` 命令的 `--exclude` 参数。

## 版本命名建议

建议使用语义化版本号：

- `v1.0.0` - 主版本.次版本.修订版本
- `v1.1.0` - 新功能发布
- `v1.0.1` - 错误修复
- `v2.0.0` - 重大更新（可能不兼容）
