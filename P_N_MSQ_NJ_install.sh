#!/bin/bash

echo "Script for Install PHP, NGINX, MYSQl, NODE"


# Install PHP
read -p "Do you want to install PHP? (y/n): " install_php
if [[ "$install_php" == "y" || "$install_php" == "Y" ]]; then
    
    echo "Please select the PHP version you want to install:"
    echo "1) PHP 7.4"
    echo "2) PHP 8.0"
    read -p "Enter the number of your choice: " php_version
    case $php_version in
        1)
            sudo apt install php7.4 php7.4-cli php7.4-fpm php7.4-mysql -y
            ;;
        2)
            sudo apt install php8.0 php8.0-cli php8.0-fpm php8.0-mysql -y
            ;;
        *)
            echo "Invalid choice, exiting."
            exit 1
            ;;
    esac
 else
 	echo "skipping PHP installation"
fi


# Install MYSQL
read -p "Do you want to install MySQL? (y/n): " install_mysql

if [[ "$install_mysql" == "Y" || "$install_mysql" == "y" ]]; then
	echo "installing mysql"
	sudo apt-get update
	sudo apt-get install -y mysql-server

	echo "Please enter the MySQL root password you want to set:"
    read -s root_password

    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$root_password';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    echo "Your MySQL root password has been set. You can access MySQL as root using the password: $root_password"
else
	echo "skipping MYSQL installation"
fi


# Install NGINX
read -p "Do you want to install Nginx? (y/n): " install_nginx
if [[ "$install_nginx" == "y" || "$install_nginx" == "Y" ]]; then
    sudo apt-get update
    sudo apt-get install nginx -y

    # Ask if user wants to enable Nginx to start on boot
    read -p "Do you want Nginx to start on boot? (y/n): " start_on_boot
    if [[ "$start_on_boot" == "y" || "$start_on_boot" == "Y" ]]; then
        sudo service nginx enable
    fi

    # Start Nginx service
    sudo service nginx start
    echo "Nginx has been installed and started."
fi


# Install Node
read -p "Do you want to install Node.js using NVM? (y/n): " install_node
if [[ "$install_node" == "y" || "$install_node" == "Y" ]]; then
    echo "Installing NVM..."
    
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    
    # Load NVM into the current shell session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Verify NVM installation
    if command -v nvm &> /dev/null; then
        echo "NVM installed successfully."
        
        echo "Available Node.js versions:"
        echo "1) Node.js 16"
        echo "2) Node.js 18 (LTS)"
        echo "3) Node.js 20 (Latest)"
        read -p "Enter the number of your choice: " node_version

        case $node_version in
            1)
                nvm install 16
                nvm use 16
                ;;
            2)
                nvm install 18
                nvm use 18
                ;;
            3)
                nvm install 20
                nvm use 20
                ;;
            *)
                echo "Invalid choice, skipping Node.js installation."
                ;;
        esac

        # Verify Node.js installation
        node -v
        npm -v
        echo "Node.js and NPM installed successfully."
    else
        echo "NVM installation failed."
    fi
else
    echo "Skipping Node.js installation"
fi

echo "Installation Script Completed!"