#!/bin/bash

# 下载安装脚本
download_script() {
    local script_url="https://raw.githubusercontent.com/atianshow/ygmaa/main/install.sh"
    echo "正在下载安装脚本..."
    if ! curl -sSfL -o install.sh "$script_url"; then
        echo "下载安装脚本失败，请检查网络连接或手动下载安装脚本。"
        exit 1
    fi
}

# 执行安装脚本
execute_script() {
    echo "正在执行安装脚本..."
    chmod +x install.sh
    ./install.sh
}

# 主函数
main() {
    download_script
    execute_script
}

# 函数：更新系统
update_system() {
    echo "正在更新系统..."
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update && sudo apt-get upgrade -y
    elif [ -x "$(command -v yum)" ]; then
        sudo yum update -y
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf update -y
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper refresh && sudo zypper update -y
    else
        echo "不支持的包管理器，请手动更新。"
        exit 1
    fi
}

# 函数：安装 Docker
install_docker() {
    echo "正在安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    if [ $? -eq 0 ]; then
        echo "Docker 安装成功。"
        # 将 Docker 命令添加到 PATH 中
        sudo ln -s /usr/bin/docker /usr/local/bin/docker
    else
        echo "Docker 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：安装 Docker Compose
install_docker_compose() {
    echo "正在安装 Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    if [ $? -eq 0 ]; then
        echo "Docker Compose 安装成功。"
        # 将 Docker Compose 命令添加到 PATH 中
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    else
        echo "Docker Compose 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：安装 Portainer
install_portainer() {
    echo "正在安装 Portainer..."
    docker volume create portainer_data
    docker run -d -p 9000:9000 -p 8000:8000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    if [ $? -eq 0 ]; then
        echo "Portainer 安装成功。访问 http://localhost:9000 进行配置。"
    else
        echo "Portainer 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：安装 Nginx Proxy Manager
install_nginx_proxy_manager() {
    echo "正在安装 Nginx Proxy Manager..."
    docker volume create npm_data
    docker run -d -p 80:80 -p 443:443 -p 81:81 --name=npm --restart=always -v npm_data:/data -v ./letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest
    if [ $? -eq 0 ]; then
        echo "Nginx Proxy Manager 安装成功。访问 http://localhost:81 进行配置。"
    else
        echo "Nginx Proxy Manager 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：安装 ServerStatus
install_serverstatus() {
    echo "正在安装 ServerStatus..."
    wget --no-check-certificate -qO ~/serverstatus-config.json https://raw.githubusercontent.com/cppla/ServerStatus/master/server/config.json && mkdir ~/serverstatus-monthtraffic    
    docker run -d --restart=always --name=serverstatus -v ~/serverstatus-config.json:/ServerStatus/server/config.json -v ~/serverstatus-monthtraffic:/usr/share/nginx/html/json -p 7777:80 -p 35601:35601 cppla/serverstatus:latest
    if [ $? -eq 0 ]; then
        echo "ServerStatus 安装成功。访问 http://localhost:7777 查看状态。"
    else
        echo "ServerStatus 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：安装 MySQL 并创建数据库和用户
install_mysql_and_wordpress_user() {
    local db_name="$1"
    local db_user="wordpress_user"
    local db_password="WordPressPassword123"
    local root_password="MyStrongPassword123"
    echo "正在安装 MySQL 数据库: $db_name ..."
    docker volume create "$db_name"_data
    docker run -d \
        --name "$db_name" \
        -p 3306:3306 \
        -e MYSQL_ROOT_PASSWORD="$root_password" \
        -v "$db_name"_data:/var/lib/mysql \
        mysql:latest
    if [ $? -eq 0 ]; then
        echo "MySQL 数据库 $db_name 安装成功。"
        # 等待 MySQL 启动
        sleep 10
        # 创建数据库和用户
        create_mysql_database_and_user "$db_name" "$db_user" "$db_password" "$root_password"
        echo "数据库 $db_name 和用户 $db_user 创建成功。"
    else
        echo "MySQL 数据库 $db_name 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：创建 MySQL 数据库和用户
create_mysql_database_and_user() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local root_password="$4"
    docker exec -i "$db_name" mysql -uroot -p"$root_password" << EOF
CREATE DATABASE $db_name;
CREATE USER '$db_user'@'%' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';
FLUSH PRIVILEGES;
EOF
}

# 函数：安装 WordPress
install_wordpress() {
    local site_name="$1"
    local db_host="$2"
    local db_name="$3"
    local port="$4"
    local db_user="wordpress_user"
    local db_password="WordPressPassword123"
    echo "正在安装 WordPress 网站: $site_name ..."
    docker volume create "$site_name"_data
    docker run -d \
        --name "$site_name" \
        -p "$port":80 \
        --restart=always \
        -v "$site_name"_data:/var/www/html \
        -e WORDPRESS_DB_HOST="$db_host" \
        -e WORDPRESS_DB_NAME="$db_name" \
        -e WORDPRESS_DB_USER="$db_user" \
        -e WORDPRESS_DB_PASSWORD="$db_password" \
        wordpress:latest
    if [ $? -eq 0 ]; then
        echo "WordPress 网站 $site_name 安装成功。访问 http://localhost:$port 进行配置。"
    else
        echo "WordPress 网站 $site_name 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 主函数
main() {
    # 更新系统
    update_system

    # 安装 Docker
    install_docker

    # 安装 Docker Compose
    install_docker_compose

    # 安装 Portainer
    install_portainer

    # 安装 Nginx Proxy Manager
    install_nginx_proxy_manager

    # 安装 ServerStatus
    install_serverstatus

    # 安装 MySQL 并创建数据库和用户
    install_mysql_and_wordpress_user "wordpress1"

    # 安装第一个 WordPress 网站
    install_wordpress "wp1" "localhost" "wordpress1" 8001

    # 安装第二个 MySQL 数据库并创建用户
    install_mysql_and_wordpress_user "wordpress2"

    # 安装第二个 WordPress 网站
    install_wordpress "wp2" "localhost" "wordpress2" 8002

    # ...
}

# 执行主函数
main
