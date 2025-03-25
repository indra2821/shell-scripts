#!/bin/bash

set -e  # Exit script on error

# Function to read user input
read_input() {
    local prompt_message=$1
    local user_input
    read -p "$prompt_message: " user_input
    echo "$user_input"
}

# Mask password input
read_password() {
    local prompt_message=$1
    local user_input
    read -s -p "$prompt_message: " user_input
    echo ""
    echo "$user_input"
}

# Email Configuration
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
EMAIL_FROM="rathodindrajit28@gmail.com"
EMAIL_TO="indrajitsinh.rathod-i@equestsolutions.net"
SMTP_USER="rathodindrajit28@gmail.com"
SMTP_PASS="sjpd bxvn jcid worv"

# Send email function
send_email() {
    local subject=$1
    local message=$2

    echo -e "Subject: $subject\n\n$message" | msmtp --host=$SMTP_SERVER --port=$SMTP_PORT \
        --tls=on --auth=on --user=$SMTP_USER --passwordeval="echo $SMTP_PASS" \
        --from=$EMAIL_FROM $EMAIL_TO
}

# Get MySQL credentials
DB_USER=$(read_input "Enter MySQL username")
DB_PASS=$(read_password "Enter MySQL password")
DB_NAME=$(read_input "Enter MySQL database name")

# Get backup directory
BACKUP_DIR=$(read_input "Enter the backup directory (default: /var/db_backups)")
BACKUP_DIR=${BACKUP_DIR:-/var/db_backups}

# Ensure backup directory exists
sudo mkdir -p "$BACKUP_DIR"
sudo chown "$USER:$USER" "$BACKUP_DIR"
sudo chmod 755 "$BACKUP_DIR"

# Ask whether to backup or restore
MODE=$(read_input "Do you want to (backup/restore)?")

if [[ "$MODE" == "backup" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql.gz"

    echo "Backing up database '$DB_NAME' to '$BACKUP_FILE'..."
    
    # Perform backup and check for errors
    if ! mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_FILE"; then
        echo "Backup failed!"
        send_email "MySQL Backup Failed: $DB_NAME" "Backup encountered an error. Please check logs."
        exit 1
    fi

    echo "Backup successful! File: $BACKUP_FILE"
    send_email "MySQL Backup Completed: $DB_NAME" \
        "Your database backup has been successfully created at:\n$BACKUP_FILE\n\nTimestamp: $(date)"

elif [[ "$MODE" == "restore" ]]; then
    BACKUP_FILE=$(read_input "Enter the full path of the backup file to restore")

    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file does not exist!"
        send_email "Restore Failed: $DB_NAME" "Restore failed because the specified backup file does not exist."
        exit 1
    fi

    # Check if the database exists
    DB_EXISTS=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME" || true)

    if [[ -z "$DB_EXISTS" ]]; then
        echo "Error: Database '$DB_NAME' does not exist. Please create it first."
        send_email "Restore Failed: $DB_NAME" "Database does not exist. Please create it before restoring."
        exit 1
    fi

    echo "Restoring database '$DB_NAME' from '$BACKUP_FILE'..."
    
    # Perform restore and check for errors
    if ! gunzip < "$BACKUP_FILE" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"; then
        echo "❌ Restore failed!"
        send_email "❌ Restore Failed: $DB_NAME" "Restore process encountered an error. Please check logs."
        exit 1
    fi

    echo "Restore completed successfully!"
    send_email "Restore Completed: $DB_NAME" \
        "Your database has been successfully restored from:\n$BACKUP_FILE\n\nTimestamp: $(date)"

else
    echo "❌ Invalid option. Please enter 'backup' or 'restore'."
    exit 1
fi

