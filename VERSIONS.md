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
- 14 (LTS)
- 16 (LTS)
- 18 (LTS)
- 20 (LTS，默认)

## 快速配置

### 方法 1：编辑 .env 文件（修改 Node.js 版本）

```env
# Node.js 版本 (14, 16, 18, 20)
NODE_VERSION=18
```

然后重新构建：
```bash
docker-compose build --no-cache
docker-compose up -d
```

### 方法 2：验证安装

```bash
# SSH 连接
ssh -p 2222 coder@<服务器IP>

# 检查 Python
python3 --version
pip3 --version

# 检查 Node.js
node --version
npm --version
```

## 常见场景

### 场景 1：使用不同 Node.js 版本

编辑 `.env`：
```env
NODE_VERSION=16
```

重新构建：
```bash
docker-compose build --no-cache
docker-compose up -d
```

### 场景 2：容器内安装 Python 包

```bash
ssh -p 2222 coder@<服务器IP>

# 安装常用包
pip install numpy pandas matplotlib

# 使用虚拟环境（推荐）
python3 -m venv /workspace/venv
source /workspace/venv/bin/activate
pip install -r requirements.txt
```

### 场景 3：容器内升级 Python

```bash
# 升级 pip
python3 -m pip install --upgrade pip

# 验证版本
python3 --version
```
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
