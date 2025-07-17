#!/bin/bash

# Basic configuration
SONAR_VERSION="10.4.1.88267"
SONAR_USER="sonar"
SONAR_DB="sonarqube"
SONAR_DB_USER="sonar"
SONAR_DB_PASSWORD="p3WwSeVcCvChM#0W3NB3Gu4LbJP0Ph7XV0fiwrJk"  # <-- Change this if needed

# Update and install required packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk unzip wget postgresql postgresql-contrib

# Setup PostgreSQL
sudo -u postgres psql -c "CREATE USER $SONAR_DB_USER WITH ENCRYPTED PASSWORD '$SONAR_DB_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE $SONAR_DB OWNER $SONAR_DB_USER;"

# Create sonar system user
sudo adduser --system --no-create-home --group --disabled-login $SONAR_USER

# Download and extract SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip
sudo unzip sonarqube-$SONAR_VERSION.zip
sudo mv sonarqube-$SONAR_VERSION sonarqube
sudo chown -R $SONAR_USER:$SONAR_USER /opt/sonarqube

# Configure sonar.properties
sudo bash -c "cat >> /opt/sonarqube/conf/sonar.properties <<EOF
sonar.jdbc.username=$SONAR_DB_USER
sonar.jdbc.password=$SONAR_DB_PASSWORD
sonar.jdbc.url=jdbc:postgresql://localhost/$SONAR_DB
EOF"

# Create SonarQube systemd service
sudo bash -c "cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=$SONAR_USER
Group=$SONAR_USER
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd and start SonarQube
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

# Allow port 9000
sudo ufw allow 9000

echo "---------------------------------------------"
echo "✅ SonarQube installation completed!"
echo "🔗 Access it at: http://<your-server-ip>:9000"
echo "👤 Login: admin"
echo "🔐 Password: admin"
echo "📦 Database: $SONAR_DB"
echo "👤 DB User: $SONAR_DB_USER"
echo "🔐 DB Password: $SONAR_DB_PASSWORD"
echo "---------------------------------------------"
