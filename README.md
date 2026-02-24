# VSCode Remote DinD 配置指南

## 项目结构

```txt
vscode-dind/
├── .github             # github 配置
├── .env                # 环境变量
├── .gitignore          # Git 忽略文件
├── docker-compose.yml  # 容器编排配置
├── Dockerfile          # 镜像定义
├── entrypoint.sh       # 入口文件
└── README.md           # 本文件
```

## 快速开始

### 1. 构建和启动容器

```bash
# 构建镜像（按需）
docker-compose build

# 启动容器
bash ./start.sh

# 查看日志
docker-compose logs -f vscode-dind
```

### 2. 访问方式

#### 方式 A：Web 界面（快速体验）

```txt
http://<服务器IP>:8443
密码：password
```

#### 方式 B：SSH 连接（与本地 VSCode 集成）

> 第一步：编辑本地 `~/.ssh/config`，添加：

```ini
Host vscode-dind
    HostName 127.0.0.1
    Port 2222
    User coder
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    PasswordAuthentication yes
```

> 第二步：转发 `vscode-dind` 容器服务端口到本地

```shell
# 建立转发
ssh -N -L 2222:127.0.0.1:2222 -p <远程服务器SSH端口> -o ServerAliveInterval=45 -o ServerAliveCountMax=30 <user>@<远程服务器IP>

# 没有输出代表已成功建立连接
```

> 第三步：连接远程vscode容器

```txt
1. 安装扩展：`Remote - SSH`
2. 左下角点击 `><` 符号
3. 选择 `Connect to Host...`
4. 选择 `vscode-dind`
5. 输入密码：`password`
```

## 容器内目录结构

| 容器内路径 | 映射 `volume` | 说明 |
| --------- | --------- | ---- |
| /workspace | workspace-dir | 工作区根目录 |
| /home/coder | user-dir | 用户目录 |

## 在容器内使用 Docker

```bash
# SSH 进入容器
ssh -p 2222 coder@127.0.0.1

# 或在 VSCode 中打开终端，直接执行：
docker ps
```

所有 Docker 操作都基于宿主机的 Docker daemon，但文件和进程完全隔离。

## 常见操作

### 停止容器

```bash
docker compose down
```

### 删除所有数据（谨慎！）

```bash
docker compose down -v
```

### 查看容器日志

```bash
docker compose logs -f vscode-dind
```

### 进入容器 shell

```bash
docker compose exec -u coder vscode-dind bash
```

### 重启容器

```bash
docker compose restart vscode-dind
```

## 安全建议

### 修改默认密码

```ini
DIND_PASSWORD=你的复杂密码
```

### SSH 配置

```dockerfile
# 禁用密码认证，仅允许密钥
RUN sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
```

## 扩展和工具

容器内已预装：

- Docker CLI + Docker Compose
- Git
- Node.js + npm
- Python 3 + pip
- build-essential（C/C++ 编译工具）

## 常见问题

### Q: 宿主机上会不会留下 VSCode 相关文件？

A: 不会。所有文件都在 Docker volumes 中，仅有容器进程。

### Q: 如何在容器内执行 sudo 命令而不输入密码？

A: Dockerfile 已配置 `NOPASSWD`，直接执行 `sudo <command>` 即可。

### Q: 如何持久化容器内安装的包？

A: 修改 Dockerfile 的 `RUN apt-get install` 部分，重新构建镜像。

## 下一步

1. 访问 code-server 安装扩展
2. 配置 Git（`git config --global user.name` 等）
3. 为后端项目安装依赖（PHP Composer）
4. 为前端项目安装依赖（npm/pnpm）
5. 配置调试器（XDebug for PHP, Chrome DevTools for JavaScript）

## 相关资源

- [code-server 官方文档](https://coder.com/docs/code-server)
- [VSCode Remote 文档](https://code.visualstudio.com/docs/remote/remote-overview)
- [Docker 官方文档](https://docs.docker.com/)
