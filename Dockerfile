# 基础开发环境镜像：php:8.4-bookworm
FROM php:8.4-bookworm AS php-base

RUN \
	# 安装 composer
	wget -O /usr/bin/composer https://github.com/composer/composer/releases/latest/download/composer.phar && \
	chmod +x /usr/bin/composer && \
	\
	# 使 busybox 支持特权命令
	chmod 4755 /bin/busybox && \
	\
	# 安装 php-extension-installer
	wget -O /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
	chmod +x /usr/local/bin/install-php-extensions && \
	\
	# 安装 PHP 扩展
	# IPE_GD_WITHOUTAVIF=y \
	# IPE_ICU_EN_ONLY=y \
	IPE_SWOOLE_WITHOUT_IOURING=y \
	install-php-extensions \
	@fix_letsencrypt \
	apcu \
	bcmath \
	Core \
	ctype \
	curl \
	date \
	dom \
	event \
	fileinfo \
	filter\
	gd \
	gettext \
	hash \
	iconv\
	igbinary \
	inotify \
	intl \
	json \
	libxml\
	mbstring \
	mongodb \
	mysqlnd \
	opcache \
	openssl \
	pcntl \
	pcre \
	PDO \
	pdo_mysql \
	pdo_pgsql \
	pdo_sqlite \
	Phar \
	posix \
	random \
	readline \
	redis \
	Reflection \
	session \
	SimpleXML \
	soap \
	sockets \
	sodium \
	SPL \
	sqlite3 \
	standard \
	swoole \
	sysvmsg \
	sysvsem \
	swoole \
	tokenizer \
	xlswriter \
	xml \
	xmlreader \
	xmlwriter \
	yaml \
	zip \
	zlib && \
	&& rm -rf /var/lib/apt/lists/* && \
	# 启用 APCu CLI 模式支持
	echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

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

# 复制二进制文件、配置文件和扩展库
COPY --from=php-base /usr/bin/php /usr/bin/php
COPY --from=php-base /usr/bin/phpize /usr/bin/phpize
COPY --from=php-base /usr/bin/php-config /usr/bin/php-config
COPY --from=php-base /usr/bin/composer /usr/bin/composer
COPY --from=php-base /usr/local/bin/install-php-extensions /usr/local/bin/install-php-extensions
COPY --from=php-base /usr/local/etc/php /usr/local/etc/php
COPY --from=php-base /usr/lib/php /usr/lib/php

# 切换回 coder 用户
USER coder

RUN echo "alias ll='ls -la --color=auto'" >> ~/.bashrc && \
	echo "alias la='ls -la --color=auto'" >> ~/.bashrc && \
	echo "alias ls='ls --color=auto'" >> ~/.bashrc

# 设置工作目录
WORKDIR /workspace

ENV PATH="${BASE_DIR}/.local/bin:${PATH}"

# 暴露端口
EXPOSE 8443 22

# 复制 entrypoint 脚本
COPY entrypoint.sh /entrypoint.sh

# 设置为入口点
ENTRYPOINT ["/usr/bin/tini", "--", "bash", "/entrypoint.sh"]
