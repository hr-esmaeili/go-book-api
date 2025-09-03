#!/bin/bash

# Deployment script for Go Book API
# This script should be run on the Ubuntu server

set -e

APP_NAME="go-book-api"
APP_DIR="/opt/$APP_NAME"
SERVICE_NAME="$APP_NAME"
BACKUP_DIR="/opt/backups/$APP_NAME"

echo "Starting deployment of $APP_NAME..."

# Create directories if they don't exist
sudo mkdir -p $APP_DIR
sudo mkdir -p $BACKUP_DIR

# Stop the service if it's running
echo "Stopping $SERVICE_NAME service..."
sudo systemctl stop $SERVICE_NAME || true

# Backup current version
if [ -f "$APP_DIR/$APP_NAME" ]; then
    echo "Creating backup..."
    BACKUP_FILE="$BACKUP_DIR/$APP_NAME.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$APP_DIR/$APP_NAME" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
fi

# Extract new version (assuming the tar.gz is in /tmp)
if [ -f "/tmp/$APP_NAME.tar.gz" ]; then
    echo "Extracting new version..."
    cd $APP_DIR
    sudo tar -xzf "/tmp/$APP_NAME.tar.gz"
    
    # Set proper permissions
    sudo chown -R www-data:www-data $APP_DIR
    sudo chmod +x "$APP_DIR/$APP_NAME"
    
    echo "New version extracted successfully"
else
    echo "Error: /tmp/$APP_NAME.tar.gz not found"
    exit 1
fi

# Create systemd service file
echo "Creating systemd service..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Go Book API
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
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
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
echo "Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

# Start the service
echo "Starting $SERVICE_NAME service..."
sudo systemctl start $SERVICE_NAME

# Wait a moment and check status
sleep 5
echo "Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager

# Show recent logs
echo "Recent logs:"
sudo journalctl -u $SERVICE_NAME --no-pager -n 10

# Clean up
rm -f "/tmp/$APP_NAME.tar.gz"

echo "Deployment completed successfully!"
echo "Service is running on port 8080"
echo "Check logs with: sudo journalctl -u $SERVICE_NAME -f"
