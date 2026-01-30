# 基础镜像：code-server
FROM codercom/code-server:latest

USER root

# 更新包管理器
RUN apt-get update && apt-get install -y --no-install-recommends \
	docker.io \
	docker-compose \
	git \
	curl \
	wget \
	openssh-server \
	sudo \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# 配置 SSH 服务
RUN mkdir -p /run/sshd && \
	sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
	sed -i 's/^AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config && \
	sed -i 's/^GatewayPorts.*/GatewayPorts yes/' /etc/ssh/sshd_config


# coder 用户添加到 docker 组
RUN usermod -aG docker coder && \
	usermod -aG sudo coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 创建工作目录
RUN mkdir -p /workspace && chown -R coder:coder /workspace

# 安装常用开发工具（可选）
# 安装基础工具和依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	curl \
	gnupg \
	lsb-release \
	&& rm -rf /var/lib/apt/lists/*

# 安装 Python（从源，支持版本指定）
ARG PYTHON_VERSION=3.11
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	python${PYTHON_VERSION} \
	python${PYTHON_VERSION}-pip \
	python${PYTHON_VERSION}-venv \
	python${PYTHON_VERSION}-dev \
	&& update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 \
	&& update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip${PYTHON_VERSION} 1 \
	&& rm -rf /var/lib/apt/lists/*

# 安装 Node.js（使用 NodeSource 仓库，支持版本指定）
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
	apt-get install -y --no-install-recommends \
	nodejs \
	&& rm -rf /var/lib/apt/lists/*

# 切换回 coder 用户
USER coder

# 设置工作目录
WORKDIR /workspace

# 暴露端口
EXPOSE 8443 22

# 启动脚本
RUN echo '#!/bin/bash\n\
	set -e\n\
	\n\
	# 启动 SSH 服务\n\
	sudo /etc/init.d/ssh start\n\
	\n\
	# 启动 code-server\n\
	exec code-server --bind-addr 0.0.0.0:8443 /workspace\n\
	' > /tmp/entrypoint.sh && chmod +x /tmp/entrypoint.sh

ENTRYPOINT ["/tmp/entrypoint.sh"]
