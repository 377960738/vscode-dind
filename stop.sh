#!/bin/bash

# VSCode DinD 停止脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "VSCode Remote DinD 停止脚本"
echo "========================================="
echo ""

# 检查容器是否运行
if docker ps -q -f name=vscode-dev > /dev/null 2>&1; then
    echo "⏹️  正在停止容器..."
    docker-compose -f "$SCRIPT_DIR/docker-compose.yml" down
    echo "✓ 容器已停止"
else
    echo "ℹ️  容器未运行"
fi

echo ""
echo "========================================="
echo "✓ 已停止"
echo "========================================="
