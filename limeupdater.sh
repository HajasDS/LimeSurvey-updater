#!/bin/bash
set -e

# Path to the configuration file.
CONFIG_FILE="/etc/limesurvey_update.conf"

# If the configuration file does not exist, prompt the user to enter settings.
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found. Please provide the following settings."
    
    read -p "Enter current LimeSurvey installation directory (DEST_DIR) [default: /var/www/limesurvey]: " dest_dir
    dest_dir=${dest_dir:-/var/www/limesurvey}
    
    read -p "Enter directory where the new version will be extracted (NEW_DIR) [default: \$HOME/limesurvey]: " new_dir
    new_dir=${new_dir:-"$HOME/limesurvey"}
    
    read -p "Enter base backup directory (BACKUP_BASE) [default: /var/backups]: " backup_base
    backup_base=${backup_base:-/var/backups}
    
    read -p "Enter web server type (apache2/nginx) [default: apache2]: " webserver
    webserver=${webserver:-apache2}
    
    read -p "Enter file owner and group for you limesurvey directory (e.g., www-data:www-data) [default: www-data:www-data]: " file_owner
    file_owner=${file_owner:-www-data:www-data}
    
    # Save these settings to the configuration file.
    cat <<EOF > "$CONFIG_FILE"
DEST_DIR="$dest_dir"
NEW_DIR="$new_dir"
BACKUP_BASE="$backup_base"
WEBSERVER="$webserver"
FILE_OWNER="$file_owner"
EOF

    echo "Configuration saved to $CONFIG_FILE."
fi

# Load the configuration.
source "$CONFIG_FILE"

# Inform the user about the expected URL format.
echo "Please provide the download URL for the latest LimeSurvey zip file."
echo "The link should be like this example: https://download.limesurvey.org/latest-master/limesurveyX.XX.X+YYMMDD.zip"
echo "You can get the link here: https://community.limesurvey.org/downloads/"

# Prompt for the download URL of the latest LimeSurvey zip file.
read -p "Paste the URL for the latest LimeSurvey zip file: " ZIP_URL
if [ -z "$ZIP_URL" ]; then
  echo "No URL provided. Exiting."
  exit 1
fi

# Stop the chosen web server service using systemctl.
echo "Stopping $WEBSERVER..."
systemctl stop "$WEBSERVER"

# Clean any previous extraction in the NEW_DIR.
echo "Cleaning previous extraction files in $NEW_DIR..."
rm -rf "$NEW_DIR"/*

# Download the zip file to a temporary location.
ZIP_FILE="/tmp/limesurvey.zip"
echo "Downloading LimeSurvey zip file from $ZIP_URL..."
wget -O "$ZIP_FILE" "$ZIP_URL"

# Determine the top-level directory name inside the zip file.
TOP_DIR=$(unzip -Z -1 "$ZIP_FILE" | head -n 1 | cut -d/ -f1)
if [ -z "$TOP_DIR" ]; then
  echo "Could not determine the top-level directory in the zip file. Exiting."
  exit 1
fi
echo "Zip file will extract to top-level directory: $TOP_DIR"

# Unzip the downloaded file into NEW_DIR.
echo "Unzipping file into $NEW_DIR..."
unzip "$ZIP_FILE" -d "$NEW_DIR"

# Create a backup of the current LimeSurvey installation.
BACKUP_DIR="$BACKUP_BASE/limesurvey_$(date '+%y%m%d_%H%M')"
echo "Backing up current installation from $DEST_DIR to $BACKUP_DIR..."
cp -ra "$DEST_DIR" "$BACKUP_DIR"

# Delete old backups if there are more than 10.
echo "Checking for old backups in $BACKUP_BASE..."
backup_count=$(ls -1 "$BACKUP_BASE"/limesurvey_* 2>/dev/null | wc -l)
if [ "$backup_count" -gt 10 ]; then
    echo "Found $backup_count backups, deleting the oldest ones..."
    # List backups sorted in ascending order (oldest first) and delete the oldest ones so only 10 remain.
    backups_to_delete=$(ls -1 "$BACKUP_BASE"/limesurvey_* | sort | head -n $(($backup_count - 10)))
    for backup in $backups_to_delete; do
        echo "Deleting old backup: $backup"
        rm -rf "$backup"
    done
fi

# Sync new version files to the destination.
# Excludes:
#   - application/config/security.php
#   - application/config/config.php
#   - the upload directory
echo "Syncing new files to $DEST_DIR..."
rsync -av --exclude='application/config/security.php' \
          --exclude='application/config/config.php' \
          --exclude='upload' \
          "$NEW_DIR/$TOP_DIR/" "$DEST_DIR/"

# Set proper ownership for the LimeSurvey directory.
echo "Setting ownership for $DEST_DIR to $FILE_OWNER..."
chown -R "$FILE_OWNER" "$DEST_DIR"

# Update the database schema using LimeSurvey's console command.
echo "Updating the database..."
php "$DEST_DIR/application/commands/console.php" updatedb

# Restart the web server service using systemctl.
echo "Starting $WEBSERVER..."
systemctl start "$WEBSERVER"

echo "LimeSurvey update completed successfully."
