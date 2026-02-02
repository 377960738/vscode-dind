#!/bin/bash

# VSCode DinD 启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "VSCode Remote DinD 启动脚本"
echo "========================================="
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ 错误：Docker 服务未运行"
    echo "请先启动 Docker 服务：sudo systemctl start docker"
    exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# 加载 .env（如果存在）
if [ -f "$SCRIPT_DIR/.env" ]; then
    # shellcheck disable=SC1090
    set -o allexport; source "$SCRIPT_DIR/.env"; set +o allexport
fi

IMAGE_NAME="${IMAGE:-swr.cn-north-4.myhuaweicloud.com/sibianjin/vscode-dind:dev}"
VSCODE_PWD="${VSCODE_PASSWORD:-${PASSWORD:-password}}"
SUDO_PWD="${SUDO_PASSWORD:-$VSCODE_PWD}"
SERVICE_NAME="vscode-dev"
VOL_CONFIG="vscode-dind_vscode-config"
VOL_LOCAL="vscode-dind_vscode-local"
BUSYBOX_IMAGE="busybox:latest"

echo "== VSCode DinD 启动器 =="
echo "工作目录: $SCRIPT_DIR"
echo "镜像: $IMAGE_NAME"
echo ""

# 1) 检查 Docker 可用性
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker 未运行。请先启动 Docker 服务。"
    exit 1
fi
echo "✓ Docker 可用"

# 2) 确保命名卷存在
docker volume inspect "$VOL_CONFIG" >/dev/null 2>&1 || docker volume create "$VOL_CONFIG"
docker volume inspect "$VOL_LOCAL"  >/dev/null 2>&1 || docker volume create "$VOL_LOCAL"
echo "✓ 命名卷已存在或已创建: $VOL_CONFIG, $VOL_LOCAL"

# 3) 构建镜像（如果你想总是使用本地最新构建，可以保留 --no-cache）
echo "📦 构建镜像..."
docker compose -f "$COMPOSE_FILE" build --quiet || docker compose -f "$COMPOSE_FILE" build

# 4) 启动容器（后台）
echo "🚀 启动容器..."
docker compose -f "$COMPOSE_FILE" up -d

# 等候容器微秒级启动
sleep 2

# 5) 等待服务 up 状态（最多 30 秒）
echo "⏳ 等待容器变为 running..."
for i in $(seq 1 30); do
    STATUS=$(docker inspect -f '{{.State.Status}}' "$SERVICE_NAME" 2>/dev/null || echo "missing")
    if [ "$STATUS" = "running" ]; then
        echo "✓ 容器 $SERVICE_NAME 正在运行"
        break
    fi
    sleep 1
done

if [ "$STATUS" != "running" ]; then
    echo "❌ 容器未能进入 running 状态（当前: $STATUS），请查看日志："
    docker compose -f "$COMPOSE_FILE" logs --no-color --tail=200 "$SERVICE_NAME"
    exit 1
fi

# 6) 获取容器内 coder 的 UID:GID（在运行的容器里读取）
CODER_UID=$(docker compose exec -T "$SERVICE_NAME" id -u coder 2>/dev/null || echo "1000")
CODER_GID=$(docker compose exec -T "$SERVICE_NAME" id -g coder 2>/dev/null || echo "1000")
echo "容器内 coder UID:GID = ${CODER_UID}:${CODER_GID}"

# 7) 在命名卷上修正属主（使用 busybox 临时容器）
echo "🔧 修正命名卷属主 -> ${CODER_UID}:${CODER_GID}"
docker run --rm -v "${VOL_CONFIG}":/data "$BUSYBOX_IMAGE" sh -c "chown -R ${CODER_UID}:${CODER_GID} /data || true"
docker run --rm -v "${VOL_LOCAL}":/data "$BUSYBOX_IMAGE" sh -c "chown -R ${CODER_UID}:${CODER_GID} /data || true"
echo "✓ 卷属主修复完成"

# 8) 设置容器内 coder 的 SSH 密码（使用 root 执行 chpasswd）
echo "🔐 设置 coder SSH 密码（来自 VSCODE_PASSWORD / PASSWORD）"
docker compose exec -T --user root "$SERVICE_NAME" sh -c "echo 'coder:${SUDO_PWD}' | chpasswd" || {
    echo "警告：未能通过 exec 修改密码（请手动检查）"
}

# 9) 让容器内拥有访问 Docker socket 的组
#    方法：读取宿主机 /var/run/docker.sock 的 GID，然后在容器内创建同 gid 的组并把 coder 加入
DOCKER_SOCK="/var/run/docker.sock"
if [ -S "$DOCKER_SOCK" ]; then
    DOCKER_GID=$(stat -c '%g' "$DOCKER_SOCK" 2>/dev/null || echo "")
    if [ -n "$DOCKER_GID" ]; then
        echo "🐳 宿主机 docker.sock GID = $DOCKER_GID"
        echo "→ 在容器内创建同 gid 的组并将 coder 加入"
        docker compose exec -T --user root "$SERVICE_NAME" sh -c "getent group docker-host >/dev/null || groupadd -g ${DOCKER_GID} docker-host || true; usermod -aG docker-host coder || true" || {
            echo "警告：在容器内创建组或添加用户失败（可能已存在）"
        }
        # 若需要立刻使组权限生效，重启容器（可选）
        echo "重启容器以应用组变更..."
        docker compose -f "$COMPOSE_FILE" restart "$SERVICE_NAME"
        sleep 2
    else
        echo "警告：无法读取 $DOCKER_SOCK 的 gid，跳过组创建"
    fi
else
    echo "警告：宿主机未检测到 $DOCKER_SOCK，跳过 docker socket 步骤"
fi

# 10) 最后检查：容器内能否运行 docker ps（若挂载并权限正确）
echo "🔎 验证容器内 docker 访问权限（docker ps）"
if docker compose exec -T "$SERVICE_NAME" docker ps >/dev/null 2>&1; then
    echo "✓ 容器内可访问 Docker daemon"
else
    echo "⚠ 容器内无法访问 Docker daemon（可能是权限或 compose 版本问题）。可尝试手动在宿主机上调整 /var/run/docker.sock 的权限："
    echo "  sudo chown root:${DOCKER_GID} /var/run/docker.sock && sudo chmod 660 /var/run/docker.sock"
fi

# 11) 显示访问信息
HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
echo ""
echo "========================================="
echo "✅ 启动完成"
echo "Web:   http://$HOST_IP:8443   (密码: $VSCODE_PWD)"
echo "SSH:   ssh -p 2222 coder@$HOST_IP  (密码: $SUDO_PWD)"
echo "查看日志: docker compose -f $COMPOSE_FILE logs -f $SERVICE_NAME"
echo "========================================="
