#!/bin/bash

set -e

# Configuration
EXPORTER_USER="mysqld_exporter"
EXPORTER_PORT=9104
EXPORTER_VERSION=$(curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest | grep tag_name | cut -d '"' -f 4)

# Prompt for Exporter password
read -s -p "Enter password to create for MySQL Exporter user: " EXPORTER_PASS
echo

# Prompt for MySQL root password
read -s -p "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
echo

# Create system user
echo "Creating dedicated system user..."
sudo useradd -rs /bin/false $EXPORTER_USER || true

# Download and install MySQL Exporter
echo "Downloading mysqld_exporter..."
wget https://github.com/prometheus/mysqld_exporter/releases/download/${EXPORTER_VERSION}/mysqld_exporter-${EXPORTER_VERSION#v}.linux-amd64.tar.gz

echo "Extracting exporter..."
tar xvf mysqld_exporter-${EXPORTER_VERSION#v}.linux-amd64.tar.gz
sudo mv mysqld_exporter-${EXPORTER_VERSION#v}.linux-amd64/mysqld_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/mysqld_exporter

# Configure exporter MySQL credentials
echo "Creating exporter credentials file..."
sudo tee /etc/.mysqld_exporter.cnf > /dev/null <<EOF
[client]
user=$EXPORTER_USER
password=$EXPORTER_PASS
EOF

sudo chown $EXPORTER_USER:$EXPORTER_USER /etc/.mysqld_exporter.cnf
sudo chmod 600 /etc/.mysqld_exporter.cnf

# Create MySQL exporter user and grant permissions
echo "Creating MySQL user and assigning privileges..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE USER IF NOT EXISTS '$EXPORTER_USER'@'localhost' IDENTIFIED BY '$EXPORTER_PASS';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '$EXPORTER_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create systemd service
echo "Setting up systemd service..."
sudo tee /etc/systemd/system/mysql_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus MySQL Exporter
After=network.target

[Service]
User=$EXPORTER_USER
Group=$EXPORTER_USER
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \\
  --config.my-cnf=/etc/.mysqld_exporter.cnf \\
  --collect.global_status \\
  --collect.info_schema.innodb_metrics \\
  --collect.auto_increment.columns \\
  --collect.info_schema.processlist \\
  --collect.binlog_size \\
  --collect.info_schema.tablestats \\
  --collect.global_variables \\
  --collect.info_schema.query_response_time \\
  --collect.info_schema.userstats \\
  --collect.info_schema.tables \\
  --collect.perf_schema.tablelocks \\
  --collect.perf_schema.file_events \\
  --collect.perf_schema.eventswaits \\
  --collect.perf_schema.indexiowaits \\
  --collect.perf_schema.tableiowaits \\
  --collect.slave_status \\
  --web.listen-address=0.0.0.0:$EXPORTER_PORT

[Install]
WantedBy=multi-user.target
EOF

# Reload, enable, and start service
echo "Starting mysqld_exporter service..."
sudo systemctl daemon-reload
sudo systemctl enable mysql_exporter
sudo systemctl start mysql_exporter

# Show service status
sudo systemctl status mysql_exporter --no-pager
