#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
NODE_EXPORTER_VERSION="1.8.2"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
TEMP_DIR="$HOME/node_exporter"

# Download and extract Node Exporter
wget "$DOWNLOAD_URL" -O node_exporter.tar.gz
tar xvf node_exporter.tar.gz
rm -f node_exporter.tar.gz

# Move and set permissions
mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" "$TEMP_DIR"
chmod +x "$TEMP_DIR/node_exporter"
sudo mv "$TEMP_DIR/node_exporter" /usr/bin/
rm -rf "$TEMP_DIR"

# Verify installation
node_exporter --version

# Create systemd service
sudo tee /etc/systemd/system/node_exporterd.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$(whoami)
ExecStart=/usr/bin/node_exporter
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable node_exporterd
sudo systemctl start node_exporterd
sudo systemctl status node_exporterd
