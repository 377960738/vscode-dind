# 开发工具版本配置指南

## 支持的版本

### Python 版本
- 3.8
- 3.9
- 3.10
- 3.11（默认）
- 3.12

### Node.js 版本
- 14 (LTS)
- 16 (LTS)
- 18 (LTS)
- 20 (LTS，默认)

## 快速配置

### 方法 1：编辑 .env 文件（推荐）

编辑 `.env` 文件中的版本配置：

```env
# Python 版本 (3.8, 3.9, 3.10, 3.11, 3.12)
PYTHON_VERSION=3.11

# Node.js 版本 (14, 16, 18, 20)
NODE_VERSION=20
```

然后重新构建镜像：
```bash
docker-compose build --no-cache
docker-compose up -d
```

### 方法 2：命令行指定（一次性）

```bash
# 指定 Python 3.10 和 Node.js 18
docker-compose build --build-arg PYTHON_VERSION=3.10 --build-arg NODE_VERSION=18

docker-compose up -d
```

## 验证安装的版本

进入容器后，检查版本：

```bash
# SSH 连接到容器
ssh -p 2222 coder@<服务器IP>

# 或在 VSCode 中打开终端，执行：

# 检查 Python 版本
python3 --version
pip3 --version

# 检查 Node.js 版本
node --version
npm --version
```

## 常见场景

### 场景 1：使用 Python 3.10 + Node.js 18

编辑 `.env`：
```env
PYTHON_VERSION=3.10
NODE_VERSION=18
```

然后：
```bash
docker-compose build --no-cache
docker-compose up -d
```

### 场景 2：需要多个 Python 版本

如果需要在同一个容器中使用多个 Python 版本，可以扩展 Dockerfile：

```dockerfile
# 安装多个 Python 版本
RUN apt-get update && \
    apt-get install -y \
    python3.10 python3.10-pip python3.10-venv \
    python3.11 python3.11-pip python3.11-venv \
    python3.12 python3.12-pip python3.12-venv \
    && rm -rf /var/lib/apt/lists/*
```

然后通过 `python3.10` 或 `python3.11` 等直接调用。

### 场景 3：使用虚拟环境

在容器内创建 Python 虚拟环境：

```bash
# 创建虚拟环境
python3 -m venv /workspace/venv

# 激活虚拟环境
source /workspace/venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

## 自定义开发工具

### 添加更多工具

如果需要添加其他开发工具（如 PHP、Ruby、Go 等），编辑 Dockerfile：

```dockerfile
# 例如：添加 PHP 8.2
RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2 \
    php8.2-cli \
    composer \
    && rm -rf /var/lib/apt/lists/*
```

然后重新构建。

### 安装 npm 包

在容器内全局安装 npm 包：

```bash
npm install -g yarn
npm install -g pnpm
npm install -g @angular/cli
npm install -g create-react-app
```

### 安装 Python 包

在容器内安装 Python 包：

```bash
pip install -U pip
pip install flask django fastapi
```

## 性能考虑

### 构建时间

- 首次构建可能需要 5-10 分钟（取决于网络）
- 版本更换需要重新构建（`--no-cache` 清除缓存）

### 镜像大小

不同版本的组合会影响最终镜像大小：
- Python 3.11 + Node.js 20：约 1.5GB
- Python 3.8 + Node.js 14：约 1.3GB

## 故障排除

### 问题 1：构建失败，"无法获取包"

**解决方案**：
```bash
# 使用国内镜像（可选）
# 编辑 Dockerfile，在 apt-get update 之前添加：
RUN echo 'deb https://mirrors.aliyun.com/debian bullseye main' > /etc/apt/sources.list

# 或者简单地重试
docker-compose build --no-cache
```

### 问题 2：NodeSource 仓库失败

**解决方案**：
```bash
# 如果 NodeSource 仓库不可用，编辑 Dockerfile 使用备选方法：
# 改为使用 apt 默认仓库（版本可能较旧）
RUN apt-get update && apt-get install -y nodejs npm

# 然后通过 npm 升级到所需版本
RUN npm install -g n
RUN n 20.0.0
```

### 问题 3：验证版本不正确

```bash
# 检查容器内实际版本
docker-compose exec -u coder vscode-dev python3 --version
docker-compose exec -u coder vscode-dev node --version
```

## 下次更新镜像

如果 code-server 基础镜像有更新，重新构建：

```bash
docker pull codercom/code-server:latest
docker-compose build --pull --no-cache
docker-compose up -d
```

## 参考资源

- [NodeSource Node.js Repository](https://github.com/nodesource/distributions)
- [Debian Python Packages](https://packages.debian.org/search?keywords=python)
- [code-server Documentation](https://coder.com/docs/code-server)
