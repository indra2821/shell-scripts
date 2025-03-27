#!/bin/bash

echo "Script for Install PHP, Apache2, mariaDB, NODE"

echo "Script to Install Apache2"


# Install Apache2
read -p "Do you want to install Apache2? (y/n): " install_apache
if [[ "$install_apache" == "y" || "$install_apache" == "Y" ]]; then
    sudo apt-get install -y apache2

    # Start Apache2 service
    sudo service apache2 start

    # Enable Apache2 to start on boot
    sudo service apache2 enable

    echo "Apache2 has been installed and started."
else
    echo "Skipping Apache2 installation"
fi


read -p "Do you want to check Apache2 status? (y/n): " check_status
if [[ "$check_status" == "y" || "$check_status" == "Y" ]]; then
    sudo service apache2 status
fi

# Install MariaDB
read -p "Do you want to install MariaDB? (y/n): " install_mariadb
if [[ "$install_mariadb" == "y" || "$install_mariadb" == "Y" ]]; then
    sudo apt-get install -y mariadb-server

    sudo service mariadb start

    sudo service mariadb enable

    echo "MariaDB has been installed and started."
else
    echo "Skipping MariaDB installation"
fi

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


# Node.js Installation using NVM
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