# 开发工具版本配置指南

## 方案说明

本配置非常简单：

- ✅ 基础镜像：code-server（专业开发工具）
- ✅ Python：系统自带 python3（Debian stable）
- ✅ Node.js：通过 NodeSource 仓库安装（支持版本指定）

## 支持的版本

### Python 版本

- 系统自带 Python 3（Debian 内置，通常是 3.11）
- 如需其他版本，容器内 pip install 即可

### Node.js 版本

- 20 (LTS，默认)

## 配置

### 编辑 .env 文件 `（例：修改 Node.js 版本）`

```env
# Node.js 版本 (14, 16, 18, 20)
NODE_VERSION=18
```

### 然后重新构建

```bash
docker-compose build --no-cache
```

## 启动容器

```bash
docker compose up -d
```

## 验证服务

```bash
# SSH 连接
ssh-keygen -R "[127.0.0.1]:2222" 2>/dev/null && ssh -p 2222 coder@127.0.0.1

# Docker 命令测试
docker compose exec vscode-dind docker ps -a

# 检查 Python
docker-compose exec -u coder vscode-dind python3 --version
docker-compose exec -u coder vscode-dind pip3 --version

# 检查 Node.js
docker-compose exec -u coder vscode-dind node --version
docker-compose exec -u coder vscode-dind npm --version
```

## 添加更多工具 `(需重新构建)`

如果需要添加其他开发工具（如 PHP、Ruby、Go 等），编辑 Dockerfile：

```dockerfile
# 例如：添加 PHP 8.2
RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2 \
    php8.2-cli \
    composer \
    && rm -rf /var/lib/apt/lists/*
```

## 参考资源

- [NodeSource Node.js Repository](https://github.com/nodesource/distributions)
- [Debian Python Packages](https://packages.debian.org/search?keywords=python)
- [code-server Documentation](https://coder.com/docs/code-server)
