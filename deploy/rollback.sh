#!/bin/bash

# Go Book API Rollback Script
# Run this script on your Ubuntu server to rollback to the previous version

set -e

echo "🔄 Rolling back Go Book API..."

# Stop the current service
echo "⏹️  Stopping current service..."
sudo systemctl stop go-book-api

# Find the latest backup
BACKUP_FILE=$(ls -t /opt/go-book-api/go-book-api.backup.* 2>/dev/null | head -n1)

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ No backup files found!"
    exit 1
fi

echo "📦 Found backup: $BACKUP_FILE"

# Restore the backup
echo "🔄 Restoring backup..."
sudo cp "$BACKUP_FILE" /opt/go-book-api/go-book-api
sudo chmod +x /opt/go-book-api/go-book-api
sudo chown go-book-api:go-book-api /opt/go-book-api/go-book-api

# Start the service
echo "▶️  Starting service..."
sudo systemctl start go-book-api

# Wait for service to start
sleep 5

# Check service status
echo "🔍 Checking service status..."
sudo systemctl status go-book-api --no-pager

# Test health endpoint
echo "🏥 Testing health endpoint..."
if curl -f http://localhost:8080/health; then
    echo "✅ Rollback completed successfully!"
else
    echo "❌ Health check failed after rollback!"
    exit 1
fi
