# 基础镜像：code-server
FROM codercom/code-server:latest

USER root

# 安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
	docker.io \
	docker-compose \
	git \
	curl \
	wget \
	openssh-server \
	sudo \
	ca-certificates \
	python3-pip \
	python3-dev \
	&& rm -rf /var/lib/apt/lists/*

# 配置 SSH 服务
RUN mkdir -p /run/sshd && \
	sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
	sed -i 's/^AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config && \
	sed -i 's/^GatewayPorts.*/GatewayPorts yes/' /etc/ssh/sshd_config

# coder 用户添加到 docker 和 sudo 组
RUN usermod -aG docker coder && \
	usermod -aG sudo coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 创建工作目录
RUN mkdir -p /workspace && chown -R coder:coder /workspace

# 安装 Node.js（支持版本指定）
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
	apt-get update && apt-get install -y --no-install-recommends nodejs && \
	rm -rf /var/lib/apt/lists/*

# 切换回 coder 用户
USER coder

# 设置工作目录
WORKDIR /workspace

# 暴露端口
EXPOSE 8443 22

# 启动脚本：设置 SSH 密码并启动服务
RUN mkdir -p /tmp && cat > /tmp/entrypoint.sh << 'SCRIPT_EOF' && chmod 755 /tmp/entrypoint.sh
#!/bin/bash
set -e

# 从环境变量设置 coder 用户的 SSH 密码（优先使用 SUDO_PASSWORD 或 PASSWORD）
SSH_PASS="${SUDO_PASSWORD:-${PASSWORD:-password}}"
echo "coder:${SSH_PASS}" | chpasswd

# 启动 SSH 服务
sudo /etc/init.d/ssh start

# 启动 code-server
exec code-server --bind-addr 0.0.0.0:8443 /workspace
SCRIPT_EOF

ENTRYPOINT ["/tmp/entrypoint.sh"]
