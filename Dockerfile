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

# 安装 PHP（支持版本指定）
ARG PHP_VERSION=8.2
RUN curl -fsSL https://packages.sury.org/php/README.txt | bash - && \
	apt-get update && apt-get install -y --no-install-recommends \
	php${PHP_VERSION} \
	php${PHP_VERSION}-cli \
	php${PHP_VERSION}-fpm \
	php${PHP_VERSION}-apcu \
	php${PHP_VERSION}-bcmath \
	php${PHP_VERSION}-curl \
	php${PHP_VERSION}-gd \
	php${PHP_VERSION}-gettext \
	php${PHP_VERSION}-igbinary \
	php${PHP_VERSION}-intl \
	php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-mongodb \
	php${PHP_VERSION}-mysql \
	php${PHP_VERSION}-opcache \
	php${PHP_VERSION}-pgsql \
	php${PHP_VERSION}-pdo \
	php${PHP_VERSION}-pdo_mysql \
	php${PHP_VERSION}-pdo_pgsql \
	php${PHP_VERSION}-pdo_sqlite \
	php${PHP_VERSION}-redis \
	php${PHP_VERSION}-soap \
	php${PHP_VERSION}-sockets \
	php${PHP_VERSION}-sodium \
	php${PHP_VERSION}-sqlite3 \
	php${PHP_VERSION}-swoole \
	php${PHP_VERSION}-xml \
	php${PHP_VERSION}-xmlreader \
	php${PHP_VERSION}-xmlwriter \
	php${PHP_VERSION}-yaml \
	php${PHP_VERSION}-zip \
	php${PHP_VERSION}-event \
	php${PHP_VERSION}-inotify \
	php${PHP_VERSION}-xlswriter && \
	rm -rf /var/lib/apt/lists/* && \
	echo "apc.enable_cli=1" > /etc/php/${PHP_VERSION}/cli/conf.d/20-apcu.ini && \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
	chmod +x /usr/local/bin/composer && \
	echo "alias ll='ls -l'" >> ~/.bashrc && \
	echo "alias la='ls -la'" >> ~/.bashrc

# 切换回 coder 用户
USER coder

# 设置工作目录
WORKDIR /workspace

# 暴露端口
EXPOSE 8443 22

# 复制 entrypoint 脚本
COPY entrypoint.sh /entrypoint.sh

# 设置为入口点
ENTRYPOINT ["/usr/bin/tini", "--", "bash", "/entrypoint.sh"]
