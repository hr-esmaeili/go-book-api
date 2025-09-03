#!/bin/bash

# Simple deployment script for Go Book API
# This script just runs the binary directly without systemd

set -e

APP_NAME="go-book-api"
APP_DIR="$HOME/$APP_NAME"
PID_FILE="$APP_DIR/$APP_NAME.pid"

echo "Starting simple deployment of $APP_NAME..."

# Create directory if it doesn't exist
mkdir -p $APP_DIR

# Stop existing process if running
if [ -f "$PID_FILE" ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping existing process (PID: $PID)..."
        kill $PID
        sleep 2
    fi
    rm -f $PID_FILE
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

# Start the application in background
echo "Starting $APP_NAME..."
cd $APP_DIR

# Set environment variables
export PORT=8080
export DB_HOST=localhost
export DB_PORT=3306
export DB_USER=root
export DB_PASS=your_db_password
export DB_NAME=bookdb

# Start the application and save PID
nohup ./$APP_NAME > $APP_DIR/app.log 2>&1 &
echo $! > $PID_FILE

# Wait a moment and check if it's running
sleep 3
if ps -p $(cat $PID_FILE) > /dev/null 2>&1; then
    echo "Application started successfully (PID: $(cat $PID_FILE))"
    echo "Service is running on port 8080"
    echo "Check logs with: tail -f $APP_DIR/app.log"
    echo "Stop service with: kill \$(cat $PID_FILE)"
else
    echo "Failed to start application. Check logs:"
    cat $APP_DIR/app.log
    exit 1
fi

# Clean up
rm -f "/tmp/$APP_NAME.tar.gz"

echo "Simple deployment completed successfully!"
