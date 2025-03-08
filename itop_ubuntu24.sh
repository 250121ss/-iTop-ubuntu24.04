#!/bin/bash

# Variables
ITOP_VERSION="3.2.0-beta1-13543"
ITOP_URL="https://sourceforge.net/projects/itop/files/itop/3.2.0-beta1/iTop-$ITOP_VERSION.zip"
DOCUMENT_ROOT="/var/www/html"
APACHE_USER="www-data"
DB_NAME="itop_db"
DB_USER="itop_user"
DB_PASS="itop_password"

# Update and upgrade system
echo "[INFO] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required dependencies
echo "[INFO] Installing Apache, MariaDB, PHP, and necessary extensions..."
sudo apt install -y apache2 mariadb-server php php-cli php-mysqli php-gd php-xml php-zip php-mbstring \
                    php-curl php-soap php-apcu php-ldap unzip acl wget

# Enable and start Apache & MariaDB
echo "[INFO] Enabling and starting Apache & MariaDB..."
sudo systemctl enable --now apache2 mariadb

# Secure MariaDB (automated)
echo "[INFO] Securing MariaDB..."
sudo mysql_secure_installation <<EOF

y
y
y
y
y
EOF

# Create iTop database and user
echo "[INFO] Setting up MariaDB database and user..."
sudo mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Download and extract iTop
echo "[INFO] Downloading and extracting iTop..."
cd /tmp
wget -O itop.zip "$ITOP_URL"
sudo unzip -o itop.zip "web/*" -d "$DOCUMENT_ROOT"
sudo mv "$DOCUMENT_ROOT/web/"* "$DOCUMENT_ROOT/"
sudo rmdir "$DOCUMENT_ROOT/web"
sudo rm -f /tmp/itop.zip

# Set proper permissions
echo "[INFO] Setting permissions..."
sudo setfacl -dR -m u:"$APACHE_USER":rwX "$DOCUMENT_ROOT/data" "$DOCUMENT_ROOT/log"
sudo setfacl -R -m u:"$APACHE_USER":rwX "$DOCUMENT_ROOT/data" "$DOCUMENT_ROOT/log"

# Create necessary directories
echo "[INFO] Creating additional directories..."
cd "$DOCUMENT_ROOT"
sudo mkdir -p env-production env-production-build
sudo chown "$APACHE_USER:$APACHE_USER" conf env-production env-production-build

# Enable Apache mod_rewrite and set AllowOverride All
echo "[INFO] Configuring Apache..."
sudo a2enmod rewrite
sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Restart Apache
echo "[INFO] Restarting Apache..."
sudo systemctl restart apache2

echo "[SUCCESS] iTop installation completed! Access it at http://your-server-ip/setup"
