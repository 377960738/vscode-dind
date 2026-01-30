# 开发工具版本配置指南

## 方案说明

本配置使用 **Miniconda** 管理 Python 版本，而不是 APT，原因包括：

- ✅ 支持任意 Python 版本（3.8 ~ 3.13）
- ✅ 无需依赖系统 PPA，更稳定可靠
- ✅ 支持快速切换 Python 版本
- ✅ 集成 conda 包管理工具
- ✅ 轻量级、跨平台

## 支持的版本

### Python 版本
通过 Miniconda，支持所有官方 Python 版本：
- 3.8.x
- 3.9.x
- 3.10.x
- 3.11.x（默认）
- 3.12.x
- 3.13.x

### Node.js 版本
- 14 (LTS)
- 16 (LTS)
- 18 (LTS)
- 20 (LTS，默认)

## 快速配置

### 方法 1：编辑 .env 文件（推荐）

编辑 `.env` 文件中的版本配置：

```env
# Python 版本 (3.8, 3.9, 3.10, 3.11, 3.12, 3.13 等)
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

### 方法 3：容器内临时切换 Python 版本

进入容器后，无需重建，即可快速切换 Python 版本：

```bash
# SSH 连接
ssh -p 2222 coder@<服务器IP>

# 列出可用 Python 版本
conda list | grep python

# 临时切换版本（会影响当前 shell）
python3.10 --version

# 或创建新环境
conda create -n py310 python=3.10
conda activate py310
python --version  # 3.10

# 切换回主环境
conda deactivate
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

# 检查 Conda 版本和环境
conda --version
conda env list
```

### 使用 Conda 管理环境

```bash
# 创建新的 Python 3.10 环境
conda create -n py310 python=3.10

# 激活环境
conda activate py310

# 检查版本
python --version  # 3.10

# 在环境中安装包
pip install numpy pandas matplotlib

# 退出环境
conda deactivate
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

### 场景 2：在容器内创建多个 Python 环境

无需重建镜像，直接在容器内使用 conda：

```bash
# SSH 进入容器
ssh -p 2222 coder@<服务器IP>

# 创建 Python 3.8 环境
conda create -n py38 python=3.8 -y

# 创建 Python 3.12 环境
conda create -n py312 python=3.12 -y

# 列出所有环境
conda env list

# 切换到 Python 3.8
conda activate py38
python --version  # 3.8

# 切换回主环境
conda deactivate
```

### 场景 3：使用虚拟环境（推荐用于项目）

```bash
# 激活 conda 基础环境
conda activate base

# 创建项目虚拟环境
python -m venv /workspace/backend/venv

# 激活虚拟环境
source /workspace/backend/venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 退出虚拟环境
deactivate
```

### 场景 4：同时使用多个 Python 版本

```bash
# 在容器内打开多个终端，分别激活不同环境
# Terminal 1
conda activate py38
python script1.py

# Terminal 2
conda activate py312
python script2.py
```

## 自定义开发工具

### 添加更多 Python 包到基础环境

如果需要在容器启动时预装 Python 包，编辑 Dockerfile：

```dockerfile
# 在 # 更新 Python 和 pip 之后添加
RUN pip install -U pip setuptools wheel && \
    pip install numpy pandas matplotlib jupyter jupyter-lab ipython
```

### 添加其他系统工具

编辑 Dockerfile，在 `# 安装基础工具和依赖` 部分添加：

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	curl \
	wget \
	git \
	ca-certificates \
	php-cli \
	ruby \
	go-lang \
	&& rm -rf /var/lib/apt/lists/*
```

### 安装更多 npm 包

在容器内全局安装 npm 包：

```bash
npm install -g yarn
npm install -g pnpm
npm install -g @angular/cli
npm install -g create-react-app
npm install -g typescript
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

### 问题 1：Miniconda 下载失败

**解决方案**：
```bash
# 如果官方源太慢，编辑 Dockerfile，使用镜像源
# 在 wget 之前添加
RUN mkdir -p ~/.condarc && echo "channels:\n  - https://mirrors.aliyun.com/anaconda/pkgs/free\n  - https://mirrors.aliyun.com/anaconda/cloud/conda-forge" > ~/.condarc

# 然后重试
docker-compose build --no-cache
```

### 问题 2：构建时 Miniconda 仓库连接超时

**解决方案**：
```bash
# 增加超时时间
docker-compose build --no-cache --progress=plain 2>&1 | tail -100

# 如果超时，重试几次（通常能成功）
docker-compose build --no-cache
```

### 问题 3：容器内 Python 版本不符合预期

```bash
# 检查 base 环境的 Python 版本
conda run -n base python --version

# 查看可用的 Python 版本
conda search python | grep "^python"

# 更新 base 环境中的 Python 版本
conda install -n base python=3.12 -y
```

### 问题 4：NodeSource 仓库失败

```bash
# 如果 NodeSource 仓库不可用，镜像会自动重试
# 如果还是失败，检查网络连接
docker-compose logs vscode-dev | grep -i node

# 手动在容器内安装 Node.js
docker-compose exec -u root vscode-dev bash
apt-get install -y nodejs npm
exit
```

### 问题 5：Conda 环境太大或磁盘不足

```bash
# 清理 Conda 缓存
conda clean -all -y

# 删除不用的环境
conda env remove -n old_env

# 查看磁盘使用
du -sh /opt/conda
du -sh ~/
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
