#!/bin/bash

# User Data script for the Frontend Builder Instance (Amazon Linux 2023)
# ---------------------------------------------------------------------

# 1. CONFIGURATION
BACKEND_LB_ADDRESS="internal-back-end-lb-442362037.ap-south-1.elb.amazonaws.com"

REPO_URL="https://github.com/aws-samples/aws-three-tier-web-architecture-workshop.git"
CLONE_DIR="/opt/app-repo"
APP_DIR="${CLONE_DIR}/application-code/web-tier"
BUILD_DIR="${APP_DIR}/build" # Location for build artifacts

# Log file for troubleshooting
LOG_FILE="/var/log/frontend-setup.log"
exec > >(tee -a $LOG_FILE) 2>&1
echo "Starting frontend user data execution at $(date)"

# 2. INSTALL BASE PACKAGES AND DEPENDENCIES
echo "Installing base packages: git, nginx, and required libraries..."
sudo dnf update -y
sudo dnf install -y git nginx libatomic

# 3. CLONE REPOSITORY
echo "Cloning repository from ${REPO_URL}..."
mkdir -p ${CLONE_DIR}
git clone ${REPO_URL} ${CLONE_DIR}
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to clone repository."
  exit 1
fi
echo "Repository cloned successfully to ${CLONE_DIR}"

# 4. NODE.JS (NVM) AND APPLICATION BUILD
echo "Installing NVM, Node.js, and application dependencies..."
cd ${APP_DIR}

# Set HOME and NVM_DIR BEFORE installing NVM to install it correctly
export HOME="/root"
export NVM_DIR="$HOME/.nvm"

# Install NVM from official raw script
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM into current shell
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Verify NVM installation
command -v nvm || { echo "ERROR: nvm failed to install or load"; exit 1; }

# Install latest Node.js LTS & use it
nvm install --lts
nvm use --lts

# Install app dependencies and build frontend
npm install
echo "Running frontend application build..."
npm run build
if [ $? -ne 0 ]; then
  echo "ERROR: npm run build failed."
  exit 1
fi
echo "Build complete. Static assets available at ${BUILD_DIR}"

# 5. NGINX CONFIGURATION (Reverse Proxy and Static Files)
echo "Configuring Nginx reverse proxy..."

cat <<EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                  '\$status \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for"';

  access_log /var/log/nginx/access.log main;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 4096;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  server {
    listen 80;
    server_name localhost;

    # Proxy /api calls to backend load balancer
    location /api {
      proxy_pass http://${BACKEND_LB_ADDRESS};
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Serve static build assets
    root ${BUILD_DIR};
    index index.html;

    # SPA routing fallback
    location / {
      try_files \$uri \$uri/ /index.html;
    }
  }
}
EOF

# 6. FIX PERMISSIONS AND START NGINX
echo "Fixing permissions for Nginx..."
chown -R nginx:nginx ${CLONE_DIR}

echo "Starting and enabling Nginx service..."
systemctl enable nginx
systemctl start nginx

echo "Frontend setup complete successfully at $(date)"
