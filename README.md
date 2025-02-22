# LimeSurvey Updater Script

This Bash script automates the process of updating your LimeSurvey installation. It downloads the latest LimeSurvey zip file, extracts it, creates a timestamped backup of your current installation, syncs new files (while preserving custom configuration and uploads), updates file ownership and the database, and finally restarts your web server.

## Features

- **Interactive Configuration:**  
  On the first run, the script will prompt you to enter:
  - The current LimeSurvey installation directory (default: `/var/www/limesurvey`)
  - The extraction directory (default: `$HOME/limesurvey`)
  - The base backup directory (default: `/var/backups`)
  - The web server type (`apache2` or `nginx`, default: `apache2`)
  - The file owner and group (default: `www-data:www-data`)
  
  These settings are saved in a configuration file for subsequent runs.

- **Automated Update Process:**  
  The script performs the following tasks:
  1. Stops the web server using `systemctl`.
  2. Downloads the specified LimeSurvey zip file.
  3. Extracts the zip file into the specified extraction directory.
  4. Creates a backup of the current LimeSurvey installation with a timestamp (format: `limesurvey_YYMMDD_HHMM`).
  5. Deletes old backups if there are more than 10 backups.
  6. Syncs the new files to your installation directory using `rsync` (excluding key configuration files and the upload directory).
  7. Updates file ownership.
  8. Runs the LimeSurvey database update command.
  9. Restarts the web server.

- **User Guidance:**  
  When prompted for the LimeSurvey zip file URL, the script shows:
  
  > The link should be like this example:  
  > `https://download.limesurvey.org/latest-master/limesurveyX.XX.X+YYMMDD.zip`  
  > You can get the link here: [https://community.limesurvey.org/downloads/](https://community.limesurvey.org/downloads/)

## Requirements

- Bash
- systemd (with `systemctl`)
- `wget`
- `unzip`
- `rsync`
- PHP
- Sudo privileges

## Getting Started

### 1. Download the script

Download the script to your local machine:

```bash
wget https://github.com/HajasDS/LimeSurvey-updater/blob/main/limeupdater.sh
```

### 2. Make the Script Executable

Run the following command to make the script executable:

```bash
chmod +x limeupdater.sh
```

### 3. Run the Script

```bash
sudo ./limeupdater.sh
```

## Configuration File

The script saves your configuration settings in the following file:
```bash
/etc/limesurvey_update.conf
```
## Sample Configuration File

Below is a sample of what your configuration file might look like:
```bash
# /etc/limesurvey_update.conf
DEST_DIR="/var/www/limesurvey"
NEW_DIR="$HOME/limesurvey"
BACKUP_BASE="/var/backups"
WEBSERVER="apache2"
FILE_OWNER="www-data:www-data"
```
## Editing the Configuration

To modify the settings, open the configuration file with your favorite text editor:
```bash
sudo nano /etc/limesurvey_update.conf
```
Make your changes, then save and exit.

## Resetting the Configuration

To reset the configuration and re-run the interactive setup, delete the configuration file:
```bash
sudo rm /etc/limesurvey_update.conf
```

## Disclaimer

Warning: Always test this script in a staging environment before using it in production. Use at your own risk.

## Contributing

Contributions and suggestions are welcome! Feel free to open issues or submit pull requests.