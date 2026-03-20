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
	# 安装 PHP 依赖库 (Debian 版)
	gnupg2 \
	lsb-release \
	apt-transport-https \
	software-properties-common \
	xml2 \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	libpng-dev \
	libjpeg-dev \
	libfreetype6-dev \
	libzip-dev \
	libonig-dev \
	libxslt1-dev \
	libicu-dev \
	libreadline-dev \
	libsqlite3-dev \
	libyaml-dev \
	libevent-dev \
	libmagickwand-dev \
	zlib1g-dev \
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
RUN curl -sSL https://packages.sury.org/php/+archive.key | gpg --dearmor -o /usr/share/keyrings/php-sury.gpg && \
	echo "deb [signed-by=/usr/share/keyrings/php-sury.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php-sury.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
	php${PHP_VERSION} \
	php${PHP_VERSION}-cli \
	php${PHP_VERSION}-fpm \
	php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-xml \
	php${PHP_VERSION}-curl \
	php${PHP_VERSION}-zip \
	php${PHP_VERSION}-intl \
	php${PHP_VERSION}-readline \
	php${PHP_VERSION}-pdo \
	php${PHP_VERSION}-mysql \
	php${PHP_VERSION}-pgsql \
	php${PHP_VERSION}-sqlite3 \
	php${PHP_VERSION}-soap \
	php${PHP_VERSION}-bcmath \
	php${PHP_VERSION}-gd \
	php${PHP_VERSION}-redis \
	php${PHP_VERSION}-apcu \
	php${PHP_VERSION}-yaml \
	php${PHP_VERSION}-event \
	php${PHP_VERSION}-sockets \
	php${PHP_VERSION}-pcntl \
	php${PHP_VERSION}-opcache \
	php${PHP_VERSION}-igbinary \
	php${PHP_VERSION}-msgpack \
	php${PHP_VERSION}-imagick \
	php${PHP_VERSION}-xdebug \
	&& ln -sf /usr/bin/php${PHP_VERSION} /usr/bin/php \
	&& ln -sf /usr/bin/php${PHP_VERSION} /usr/bin/phpize \
	&& ln -sf /usr/bin/php-config${PHP_VERSION} /usr/bin/php-config \
	&& rm -rf /var/lib/apt/lists/*

# 下载并安装 docker-php-extension-installer
RUN curl -sSL -o /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
	chmod +x /usr/local/bin/install-php-extensions
# 安装 PHP 扩展
RUN apt-get update && apt-get install -y --no-install-recommends \
	libz-dev \
	libssl-dev \
	libnghttp2-dev \
	libcares-dev \
	libuv1-dev \
	libbrotli-dev \
	&& IPE_SWOOLE_WITHOUT_IOURING=y install-php-extensions \
	@fix_letsencrypt \
	swoole \
	mongodb \
	inotify \
	xlswriter \
	&& rm -rf /var/lib/apt/lists/*

# 启用 APCu CLI
RUN echo "apc.enable_cli=1" >> /etc/php/8.4/cli/conf.d/20-apcu.ini

# 安装 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# 切换回 coder 用户
USER coder

# 设置 shell 别名（支持 ll 和 la 命令）
RUN echo "alias ll='ls -la'" >> ~/.bashrc && \
	echo "alias la='ls -la'" >> ~/.bashrc

# 设置工作目录
WORKDIR /workspace

# 暴露端口
EXPOSE 8443 22

# 复制 entrypoint 脚本
COPY entrypoint.sh /entrypoint.sh

# 设置为入口点
ENTRYPOINT ["/usr/bin/tini", "--", "bash", "/entrypoint.sh"]
