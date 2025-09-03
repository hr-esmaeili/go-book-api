#!/bin/bash

# Deployment script for Go Book API (No sudo version)
# This script deploys to a user directory and uses user-level services

set -e

APP_NAME="go-book-api"
APP_DIR="$HOME/$APP_NAME"
SERVICE_NAME="$APP_NAME"
BACKUP_DIR="$HOME/backups/$APP_NAME"

echo "Starting deployment of $APP_NAME (no sudo version)..."

# Create directories if they don't exist
mkdir -p $APP_DIR
mkdir -p $BACKUP_DIR

# Stop the service if it's running (user service)
echo "Stopping $SERVICE_NAME service..."
systemctl --user stop $SERVICE_NAME || true

# Backup current version
if [ -f "$APP_DIR/$APP_NAME" ]; then
    echo "Creating backup..."
    BACKUP_FILE="$BACKUP_DIR/$APP_NAME.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$APP_DIR/$APP_NAME" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
fi

# Extract new version (assuming the tar.gz is in /tmp)
if [ -f "/tmp/$APP_NAME.tar.gz" ]; then
    echo "Extracting new version..."
    cd $APP_DIR
    tar -xzf "/tmp/$APP_NAME.tar.gz"
    
    # Set proper permissions
    chmod +x "$APP_DIR/$APP_NAME"
    
    echo "New version extracted successfully"
else
    echo "Error: /tmp/$APP_NAME.tar.gz not found"
    exit 1
fi

# Create user systemd service file
echo "Creating user systemd service..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/$SERVICE_NAME.service <<EOF
[Unit]
Description=Go Book API
After=network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/$APP_NAME
Restart=always
RestartSec=5
Environment=PORT=8080
Environment=DB_HOST=localhost
Environment=DB_PORT=3306
Environment=DB_USER=root
Environment=DB_PASS=your_db_password
Environment=DB_NAME=bookdb

[Install]
WantedBy=default.target
EOF

# Reload systemd and enable service
echo "Reloading systemd and enabling service..."
systemctl --user daemon-reload
systemctl --user enable $SERVICE_NAME

# Start the service
echo "Starting $SERVICE_NAME service..."
systemctl --user start $SERVICE_NAME

# Wait a moment and check status
sleep 5
echo "Checking service status..."
systemctl --user status $SERVICE_NAME --no-pager

# Show recent logs
echo "Recent logs:"
journalctl --user -u $SERVICE_NAME --no-pager -n 10

# Clean up
rm -f "/tmp/$APP_NAME.tar.gz"

echo "Deployment completed successfully!"
echo "Service is running on port 8080"
echo "Check logs with: journalctl --user -u $SERVICE_NAME -f"
echo ""
echo "Note: This is a user service. To enable it to start on boot, run:"
echo "loginctl enable-linger $USER"
