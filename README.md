# VSCode Remote DinD 配置指南

## 项目结构
```
vscode-dind/
├── Dockerfile          # 镜像定义
├── docker-compose.yml  # 容器编排配置
├── .env                # 环境变量
├── .github             # github 配置
├── .gitignore          # Git 忽略文件
├── README.md           # 本文件
├── start.sh            # 一键部署
└── stop.sh             # 一键停止
```

## 快速开始

### 1. 构建和启动容器

```bash
# 构建镜像
docker-compose build

# 启动容器（后台运行）
docker-compose up -d

# 查看日志
docker-compose logs -f vscode-dev
```

### 2. 访问方式

#### 方式 A：Web 界面（推荐快速体验）
```
http://<服务器IP>:8443
密码：password
```

#### 方式 B：SSH 连接（与本地 VSCode 集成）

**第一步：配置 SSH**

编辑本地 `~/.ssh/config`，添加：
```
Host vscode-dev
    HostName <服务器IP地址>
    Port 2222
    User coder
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    PasswordAuthentication yes
```

**第二步：本地 VSCode 连接**

1. 安装扩展：`Remote - SSH`
2. 左下角点击 `><` 符号
3. 选择 `Connect to Host...`
4. 选择 `vscode-dev`
5. 输入密码：`password`

#### 方式 C：SSH 密钥连接（更安全）

```bash
# 1. 生成密钥对（如果还没有）
ssh-keygen -t ed25519 -f ~/.ssh/vscode-dev-key -N ""

# 2. 复制公钥到容器
ssh-copy-id -i ~/.ssh/vscode-dev-dev.pub -p 2222 coder@<服务器IP>

# 3. 更新 SSH 配置
# ~/.ssh/config 中添加：
Host vscode-dev
    HostName <服务器IP>
    Port 2222
    User coder
    IdentityFile ~/.ssh/vscode-dev-key
    StrictHostKeyChecking no
```

## 容器内目录结构

| 容器内路径 | 宿主机映射 | 说明 |
|-----------|-----------|------|
| `/workspace/<project-dir>` | `project-dir` | 项目目录 |
| `/home/coder/.config/code-server` | `vscode-config` volume | code-server 配置 |
| `/home/coder/.local/share/code-server` | `vscode-local` volume | 扩展和缓存 |

## Docker 隔离验证

### 验证文件隔离
```bash
# 查看容器内挂载情况
docker inspect vscode-dev | grep -A 20 "Mounts"

# 查看宿主机上的数据
docker volume ls | grep vscode

# 查看宿主机文件（仅有容器进程）
ps aux | grep code-server  # 只显示 docker 进程，不是直接运行
```

### 在容器内使用 Docker

```bash
# SSH 进入容器
ssh -p 2222 coder@<服务器IP>

# 或在 VSCode 中打开终端，直接执行：
docker ps
docker run -it ubuntu bash
docker build .
```

所有 Docker 操作都基于宿主机的 Docker daemon，但文件和进程完全隔离。

## 常见操作

### 停止容器
```bash
docker-compose down
```

### 删除所有数据（谨慎！）
```bash
docker-compose down -v
```

### 查看容器日志
```bash
docker-compose logs -f vscode-dev
```

### 进入容器 shell
```bash
docker-compose exec -u coder vscode-dev bash
```

### 重启容器
```bash
docker-compose restart vscode-dev
```

### 更新镜像
```bash
docker-compose build --no-cache
docker-compose up -d
```

## 安全建议

### 1. 修改默认密码
编辑 `.env` 文件：
```
VSCODE_PASSWORD=你的复杂密码
```

然后重启容器：
```bash
docker-compose up -d
```

### 2. 限制端口访问
使用防火墙仅允许特定 IP：
```bash
sudo ufw allow from <你的IP> to any port 8443
sudo ufw allow from <你的IP> to any port 2222
```

### 3. 使用 SSH 密钥代替密码
参考上面的"SSH 密钥连接"部分。

### 4. 修改 SSH 配置
编辑 `Dockerfile`，增强 SSH 安全：
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

### 安装额外工具

在容器内执行：
```bash
# PHP 开发工具
sudo apt-get install -y php-cli php-mbstring php-json

# 其他工具
sudo apt-get install -y <package-name>
```

## 性能优化

### 1. 使用 cached 挂载加快 I/O
```yaml
volumes:
  - /www/wwwroot/php/buildadmin:/workspace/backend:cached
```

### 2. 配置资源限制
编辑 `docker-compose.yml`，取消注释 `deploy` 部分。

### 3. 使用本地卷而非 bind mount
已在配置中为 code-server 配置和插件使用了 Docker volumes。

## 故障排除

### 无法连接到 Docker daemon
```bash
# 检查 docker socket 权限
ls -l /var/run/docker.sock

# 如果权限不足，运行：
sudo usermod -aG docker $USER
```

### SSH 连接被拒绝
```bash
# 检查 SSH 服务是否运行
docker-compose exec -u coder vscode-dev sudo /etc/init.d/ssh status

# 重启 SSH
docker-compose exec -u root vscode-dev /etc/init.d/ssh restart
```

### code-server 无法启动
```bash
# 查看日志
docker-compose logs vscode-dev

# 检查端口是否被占用
sudo lsof -i :8443
sudo lsof -i :2222
```

### 容器内文件权限问题
```bash
# 修复权限
docker-compose exec -u root vscode-dev chown -R coder:coder /workspace
```

## 常见问题

### Q: 宿主机上会不会留下 VSCode 相关文件？
A: 不会。所有文件都在 Docker volumes 中，仅有容器进程。

### Q: 如何在容器内执行 sudo 命令而不输入密码？
A: Dockerfile 已配置 `NOPASSWD`，直接执行 `sudo <command>` 即可。

### Q: 如何为 Docker 命令添加 alias？
A: 在容器内编辑 `~/.bashrc`，添加：
```bash
alias d='docker'
alias dc='docker-compose'
```

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
