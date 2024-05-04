#!/bin/bash

# 清除可能存在的 Windows 换行符
sed -i 's/\r$//' "$0"

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

# 函数：更新系统 (改进错误处理)
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
        return 1  # 返回错误代码，而不是退出
    fi
}

# 函数：更新系统 (改进错误处理)
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
        return 1  # 返回错误代码，而不是退出
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

# 函数：安装 WordPress 1
install_wordpress1() {
    echo "正在安装 WordPress 网站 wordpress1 ..."
    docker volume create wordpress1_db
    docker volume create wordpress1_wp
    docker run --restart always -e MYSQL_ROOT_PASSWORD=root_password -e MYSQL_DATABASE=wordpress1 -e MYSQL_USER=wordpress1 -e MYSQL_PASSWORD=password -v wordpress1_db:/var/lib/mysql mysql:8.0
    docker run --restart always -p 8001:80 -v wordpress1_wp:/var/www/html wordpress:latest
    if [ $? -eq 0 ]; then
        echo "WordPress1 安装成功。访问 http://localhost:8001 查看状态。"
    else
        echo "WordPress1 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：安装 WordPress 2
install_wordpress2() {
    echo "正在安装 WordPress 网站 wordpress2 ..."
    docker volume create wordpress2_db
    docker volume create wordpress2_wp
    docker run --restart always -e MYSQL_ROOT_PASSWORD=root_password -e MYSQL_DATABASE=wordpress2 -e MYSQL_USER=wordpress2 -e MYSQL_PASSWORD=password -v wordpress2_db:/var/lib/mysql mysql:8.0
    docker run --restart always -p 8002:80 -v wordpress2_wp:/var/www/html wordpress:latest
    if [ $? -eq 0 ]; then
        echo "WordPress2 安装成功。访问 http://localhost:8002 查看状态。"
    else
        echo "WordPress2 安装失败，请检查错误信息。"
        exit 1
    fi
}

# 函数：显示安装选项并安装所选的软件
choose_and_install() {
    while true; do
        echo "请选择要安装的软件："
        echo "1. Docker"
        echo "2. Docker Compose"
        echo "3. Portainer"
        echo "4. Nginx Proxy Manager"
        echo "5. ServerStatus"
        echo "6. wordpress1"
        echo "7. wordpress2"
        echo "8. 退出"

        read -p "请输入选项编号: " choice

        case "$choice" in
            1)
                install_docker
                ;;
            2)
                install_docker_compose
                ;;
            3)
                install_portainer
                ;;
            4)
                install_nginx_proxy_manager
                ;;
            5)
                install_serverstatus
                ;;
            6)
                install_wordpress1
                ;;
            7)
                install_wordpress2
                ;;
            8)
                echo "退出安装。"
                exit 0
                ;;
            *)
                echo "无效的选项，请重新选择。"
                ;;
        esac

        echo "已安装的软件："
        docker ps --format "table {{.Names}}" | tail -n +2
    done
}

# 主函数
main() {
    # 更新系统
    update_system

    # 下载安装脚本
    download_script

    # 执行安装脚本
    execute_script
    
    # 选择并安装软件
    choose_and_install
}

# 执行主函数
main
