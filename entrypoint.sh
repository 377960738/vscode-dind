#!/bin/bash
set -e

echo "🔧 DIND 开发环境自检中..."

# === 1. 修复关键目录权限 ===
if [ "$(stat -c %U:%G /home/coder)" != "coder:coder" ]; then
    echo "→ 修复目录权限..."
    sudo chown -R coder:coder /home/coder
fi

# === 2. 确保宿主docker.sock可访问 ===
DOCKER_SOCK="/var/run/docker.sock"

if [ -S "$DOCKER_SOCK" ]; then

    DOCKER_GID=$(stat -c '%g' "$DOCKER_SOCK")

    # 检查是否已创建 docker-host 组
    if ! getent group docker-host >/dev/null; then
        echo "→ 创建 GID=$DOCKER_GID 的 docker-host 组"
        sudo groupadd -g "$DOCKER_GID" docker-host || echo "   警告：groupadd 失败（可能已存在）"
    fi

    # 将 coder 加入 docker-host 组（如果尚未加入）
    if ! groups coder | grep -q '\bdocker-host\b'; then
        echo "→ 将 coder 加入 docker-host 组"
        sudo usermod -aG docker-host coder
    fi

    # 确保 socket 可读
    sudo chmod g+r "$DOCKER_SOCK"
else
    echo "→ 未挂载 ${DOCKER_SOCK}，跳过 Docker 配置"
fi

# === 3. 设置 SSH 密码 ===
if [ -n "${DIND_PASSWORD}" ]; then
    echo "→ 更新 SSH 密码..."
    echo "coder:${DIND_PASSWORD}" | sudo chpasswd
else
    echo "⚠️ 未设置 DIND_PASSWORD，SSH 密码保持默认或空"
fi

# === 4. 启动 SSH 服务（后台）===
echo "→ 启动 SSH 服务..."
sudo mkdir -p /run/sshd
sudo /usr/sbin/sshd -D -o PidFile=/run/sshd.pid &

# === 5. 启动 code-server（主进程）===
echo "运行 code-server..."
exec code-server --bind-addr 0.0.0.0:8443 /workspace
