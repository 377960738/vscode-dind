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

echo "✓ Docker 服务运行正常"

# 检查 docker.sock 权限
if [ ! -r /var/run/docker.sock ]; then
    echo "❌ 错误：无法读取 /var/run/docker.sock"
    echo "请运行：sudo usermod -aG docker $USER"
    echo "然后重新登录 Shell"
    exit 1
fi

echo "✓ Docker socket 权限正常"

# 构建镜像
echo ""
echo "📦 正在构建镜像..."
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" build

# 启动容器
echo ""
echo "🚀 正在启动容器..."
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

# 等待容器启动
echo ""
echo "⏳ 等待容器启动..."
sleep 5

# 获取容器状态
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' vscode-dev 2>/dev/null || echo "unknown")

if [ "$CONTAINER_STATUS" = "running" ]; then
    echo "✓ 容器启动成功"

    # 获取服务器 IP
    if command -v hostname &> /dev/null; then
        SERVER_IP=$(hostname -I | awk '{print $1}')
    else
        SERVER_IP="<服务器IP>"
    fi

    echo ""
    echo "========================================="
    echo "✅ VSCode Remote 已就绪"
    echo "========================================="
    echo ""
    echo "📍 访问方式："
    echo ""
    echo "1️⃣  Web 界面（推荐）："
    echo "   地址：http://$SERVER_IP:8443"
    echo "   密码：$(grep VSCODE_PASSWORD "$SCRIPT_DIR/.env" | cut -d= -f2)"
    echo ""
    echo "2️⃣  SSH 连接（VSCode Remote-SSH）："
    echo "   Host: $SERVER_IP"
    echo "   Port: 2222"
    echo "   User: coder"
    echo "   Password: $(grep VSCODE_PASSWORD "$SCRIPT_DIR/.env" | cut -d= -f2)"
    echo ""
    echo "📂 项目位置："
    echo "   后端：/workspace/backend"
    echo "   前端：/workspace/frontend"
    echo ""
    echo "🐳 Docker 隔离：完全隔离，所有文件在容器内"
    echo ""
    echo "📝 查看日志："
    echo "   docker-compose -f $SCRIPT_DIR/docker-compose.yml logs -f"
    echo ""
    echo "⏹️  停止服务："
    echo "   docker-compose -f $SCRIPT_DIR/docker-compose.yml down"
    echo "========================================="
else
    echo "❌ 容器启动失败，状态：$CONTAINER_STATUS"
    echo ""
    echo "📋 查看错误日志："
    docker-compose -f "$SCRIPT_DIR/docker-compose.yml" logs
    exit 1
fi
