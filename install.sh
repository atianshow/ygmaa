#!/bin/bash

# Function to update system
update_system() {
    echo "Updating system..."
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update -y
        sudo apt-get upgrade -y
    elif [ -x "$(command -v yum)" ]; then
        sudo yum update -y
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf update -y
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper refresh
        sudo zypper update -y
    else
        echo "Unsupported package manager. Update manually."
        exit 1
    fi
}

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
}

# Function to install Docker Compose
install_docker_compose() {
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Function to install Portainer
install_portainer() {
    echo "Installing Portainer..."
    docker volume create portainer_data
    docker run -d -p 9000:9000 -p 8000:8000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
}

# Function to install Nginx Proxy Manager
install_nginx_proxy_manager() {
    echo "Installing Nginx Proxy Manager..."
    docker volume create npm_data
    docker run -d -p 80:80 -p 443:443 -p 81:81 --name=npm --restart=always -v npm_data:/data jlesage/nginx-proxy-manager:latest
}

# Function to install certbot
install_certbot() {
    echo "Installing certbot..."
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update -y
        sudo apt-get install -y certbot
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y certbot
    else
        echo "Unsupported package manager. Install certbot manually."
        exit 1
    fi
}

# Function to request Let's Encrypt certificate
request_certificate() {
    echo "Requesting Let's Encrypt certificate..."
    sudo certbot certonly --standalone -d example.com -d www.example.com
}

# Function to install ServerStatus
install_serverstatus() {
    echo "Installing ServerStatus..."
    docker run -d --name=serverstatus -v /etc/ServerStatus:/etc/ServerStatus --net=host --restart=always cppla/serverstatus:server
}

# Main function
main() {
    update_system
    install_docker
    install_docker_compose
    install_portainer
    install_nginx_proxy_manager
    install_certbot
    request_certificate
    install_serverstatus
}

# Execute main function
main
