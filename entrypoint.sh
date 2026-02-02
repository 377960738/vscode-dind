#!/bin/bash
set -e

# 从环境变量设置 coder 用户的 SSH 密码（优先使用 SUDO_PASSWORD 或 PASSWORD）
SSH_PASS="${SUDO_PASSWORD:-${PASSWORD:-password}}"
echo "coder:${SSH_PASS}" | chpasswd

# 启动 SSH 服务
sudo /etc/init.d/ssh start

# 启动 code-server
exec code-server --bind-addr 0.0.0.0:8443 /workspace
