#!/bin/bash

# Directories where Nginx and Apache store logs
NGINX_LOG_DIR="/var/log/nginx"
APACHE_LOG_DIR="/var/log/apache2"

# Number of days to keep logs
RETENTION_DAYS=7

# Function to rotate logs
rotate_logs() {
    local log_dir=$1
    local service_name=$2

    echo "Rotating logs for $service_name..."
    
    # Compress the current log files
    find "$log_dir" -type f -name "*.log" -exec sudo gzip {} \;

    # Reload the service to start writing new logs
    sudo systemctl reload "$service_name"

    echo "Rotation completed for $service_name."
}

# Function to delete old logs
cleanup_logs() {
    local log_dir=$1
    local service_name=$2

    echo "Cleaning up logs older than $RETENTION_DAYS days for $service_name..."
    
    find "$log_dir" -type f -name "*.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;

    echo "Cleanup completed for $service_name."
}

# Rotate and clean logs for Nginx
rotate_logs "$NGINX_LOG_DIR" "nginx"
cleanup_logs "$NGINX_LOG_DIR" "nginx"

# Rotate and clean logs for Apache
rotate_logs "$APACHE_LOG_DIR" "apache2"
cleanup_logs "$APACHE_LOG_DIR" "apache2"

echo "Log rotation and cleanup completed successfully!"

