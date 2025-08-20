#!/bin/bash

set -e

# Print system info
echo "System Info:"
uname -a

# Variables
PROMTAIL_VERSION="2.4.1"
PROMTAIL_BINARY="promtail-linux-amd64"
PROMTAIL_ZIP="${PROMTAIL_BINARY}.zip"
PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v$PROMTAIL_VERSION/$PROMTAIL_ZIP"
CONFIG_URL="https://gist.githubusercontent.com/theLazyCat775/6fe9125e529221166e9f02b00244638a/raw/84f510e6f62d0e60ab95dbe7f9732a629a27eb6d/promtail-config.yaml"
CONFIG_PATH="/etc/promtail/promtail-config.yaml"
LOG_DIR="/etc/promtail/logs"
SERVICE_FILE="/etc/systemd/system/promtail.service"

# Download Promtail binary
echo "Downloading Promtail v$PROMTAIL_VERSION..."
curl -O -L "$PROMTAIL_URL"

# Unzip and install
unzip "$PROMTAIL_ZIP"
chmod +x "$PROMTAIL_BINARY"
sudo cp "$PROMTAIL_BINARY" /usr/local/bin/promtail
rm -f "$PROMTAIL_BINARY" "$PROMTAIL_ZIP"

# Check version
promtail --version

# Create directories
echo "Creating directories..."
sudo mkdir -p /etc/promtail "$LOG_DIR"

# Download config
echo "Downloading Promtail config..."
sudo curl -o "$CONFIG_PATH" -L "$CONFIG_URL"

# Set permissions
sudo chown root:root "$CONFIG_PATH"
sudo chmod 644 "$CONFIG_PATH"

# Create systemd service
echo "Creating systemd service..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail-config.yaml
Restart=on-failure
RestartSec=20
StandardOutput=append:$LOG_DIR/promtail.log
StandardError=append:$LOG_DIR/promtail.log

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
echo "Starting Promtail service..."
sudo systemctl daemon-reload
sudo systemctl enable promtail.service
sudo systemctl start promtail
sudo systemctl status promtail --no-pager

echo "✅ Promtail installation and setup complete."


