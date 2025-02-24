#!/bin/bash

set -e  # Exit script on error

# Function to read user input
read_input() {
    local prompt_message=$1
    local user_input
    read -p "$prompt_message: " user_input
    echo "$user_input"
}

# Get MySQL credentials
DB_USER=$(read_input "Enter MySQL username")
DB_PASS=$(read_input "Enter MySQL password")
DB_NAME=$(read_input "Enter MySQL database name")

# Get backup directory, default to /var/db_backups if empty
BACKUP_DIR=$(read_input "Enter the directory to store backups (default: /var/db_backups)")
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
    sudo mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_FILE"

    echo "✅ Backup successful! File: $BACKUP_FILE"

elif [[ "$MODE" == "restore" ]]; then
    BACKUP_FILE=$(read_input "Enter the full path of the backup file to restore (e.g., /var/db_backups/mydb_backup.sql.gz)")

    if [ ! -f "$BACKUP_FILE" ]; then
        echo "❌ Error: Backup file does not exist!"
        exit 1
    fi

    # Check if the database exists
    DB_EXISTS=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME" || true)

    if [[ -z "$DB_EXISTS" ]]; then
        echo "❌ Error: Database '$DB_NAME' does not exist. Please create it first."
        exit 1
    fi

    echo "Restoring database '$DB_NAME' from '$BACKUP_FILE'..."
    gunzip < "$BACKUP_FILE" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"

    echo "✅ Restore completed successfully!"

else
    echo "❌ Invalid option. Please enter 'backup' or 'restore'."
    exit 1
fi

