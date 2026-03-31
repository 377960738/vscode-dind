# 基础镜像：code-server
FROM codercom/code-server:latest

USER root

# 安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
	tini \
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
	python3-venv \
	build-essential \
	pkg-config \
	autoconf \
	automake \
	libtool \
	make m4 \
	libcurl4-openssl-dev \
	libpng-dev libjpeg-dev libfreetype6-dev \
	libzip-dev \
	libbz2-dev \
	libicu-dev \
	libpq-dev \
	libmariadb-dev \
	libsodium-dev \
	libgmp-dev \
	libxslt1-dev \
	libmagickwand-dev \
	libhiredis-dev \
	libxml2-dev sqlite3 libsqlite3-dev libssl-dev zlib1g-dev \
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
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	# 设置 root 密码（仅调试）
	echo "root:123456" | chpasswd;

# 创建工作目录
RUN mkdir -p /workspace && chown -R coder:coder /workspace

# 安装 Node.js（支持版本指定）
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
	apt-get update && apt-get install -y --no-install-recommends nodejs && \
	rm -rf /var/lib/apt/lists/*

# 切换回 coder 用户
USER coder

RUN echo "alias ll='ls -la --color=auto'" >> /home/coder/.bashrc && \
	echo "alias la='ls -la --color=auto'" >> /home/coder/.bashrc && \
	echo "alias ls='ls --color=auto'" >> /home/coder/.bashrc

# 设置工作目录
WORKDIR /workspace

# 暴露端口
EXPOSE 8443 22

# 复制 entrypoint 脚本
COPY entrypoint.sh /entrypoint.sh

# 设置为入口点
ENTRYPOINT ["/usr/bin/tini", "--", "bash", "/entrypoint.sh"]
