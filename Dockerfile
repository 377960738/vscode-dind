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
	wget \
	git \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# 安装 Miniconda（支持多个 Python 版本，更稳定）
ARG PYTHON_VERSION=3.11
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
	bash /tmp/miniconda.sh -b -p /opt/conda && \
	rm /tmp/miniconda.sh && \
	/opt/conda/bin/conda clean -afy && \
	/opt/conda/bin/conda config --system --prepend channels conda-forge && \
	/opt/conda/bin/conda install -y "python=${PYTHON_VERSION}.*" && \
	/opt/conda/bin/conda clean -afy && \
	ln -s /opt/conda/bin/python /usr/local/bin/python3 && \
	ln -s /opt/conda/bin/pip /usr/local/bin/pip3

# 更新 Python 和 pip
RUN /opt/conda/bin/pip install --upgrade pip setuptools wheel

# 设置 conda 初始化
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
	echo "conda activate base" >> /etc/bash.bashrc

# 安装 Node.js（使用 NodeSource 仓库，支持版本指定）
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - || \
	curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
	apt-get update && \
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
