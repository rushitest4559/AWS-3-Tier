#!/bin/bash

# User Data script for the Backend Builder Instance (Amazon Linux 2023)
# -------------------------------------------------------------------

# 1. CONFIGURATION
RDS_ENDPOINT="three-tier-db.cv6oeayqw5p7.ap-south-1.rds.amazonaws.com"  # No port in hostname
DB_USERNAME="admin"
DB_PASSWORD="YourPassword123!"

REPO_URL="https://github.com/aws-samples/aws-three-tier-web-architecture-workshop.git"
CLONE_DIR="/opt/app-repo"
APP_DIR="${CLONE_DIR}/application-code/app-tier"

# Log file for troubleshooting
LOG_FILE="/var/log/backend-setup.log"
exec > >(tee -a $LOG_FILE) 2>&1
echo "Starting backend user data execution at $(date)"

# 2. INSTALL BASE PACKAGES AND DEPENDENCIES
echo "Installing base packages and dependencies..."
sudo dnf update -y
sudo dnf install -y git mariadb105-server libatomic

# 3. CLONE REPOSITORY
echo "Cloning repository..."
mkdir -p ${CLONE_DIR}
git clone ${REPO_URL} ${CLONE_DIR}
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to clone repository."
  exit 1
fi

# 4. RDS DATABASE INITIALIZATION
echo "Initializing database 'webappdb'..."
DB_EXISTS=$(mysql -h ${RDS_ENDPOINT} -u ${DB_USERNAME} -p${DB_PASSWORD} -e "SHOW DATABASES LIKE 'webappdb';" | grep webappdb)

if [ -z "$DB_EXISTS" ]; then
  mysql -h ${RDS_ENDPOINT} -u ${DB_USERNAME} -p${DB_PASSWORD} <<MYSQL_COMMANDS
CREATE DATABASE webappdb;
USE webappdb;
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  amount DECIMAL(10,2),
  description VARCHAR(100)
);
INSERT INTO transactions (amount, description) VALUES (400, 'groceries');
MYSQL_COMMANDS
else
  echo "Database already exists. Skipping creation."
fi

# 5. NODE.JS (NVM) AND APPLICATION SETUP
echo "Installing NVM, Node.js, and application dependencies..."
cd ${APP_DIR}

# Set HOME and NVM_DIR early to fix NVM install path
export HOME="/root"
export NVM_DIR="$HOME/.nvm"

# Install NVM properly
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM in current shell
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Verify nvm installation
command -v nvm || { echo "ERROR: nvm failed to install or load"; exit 1; }

# Install Node.js LTS version and use it
nvm install --lts
nvm use --lts

# Install pm2 globally
npm install -g pm2

# Install app dependencies
npm install

# Add npm binaries to PATH for pm2 command availability
export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"

# 6. START AND SAVE APPLICATION SERVICE
echo "Starting backend application using PM2..."
pm2 start index.js --name "backend-api"
pm2 save

echo "Backend setup complete."
