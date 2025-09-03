#!/bin/bash

# Go Book API Server Setup Script
# Run this script on your Ubuntu server to prepare it for deployment

set -e

echo "🚀 Setting up Go Book API server..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y curl wget git unzip

# Create application user (optional, if you want to run as non-root)
echo "👤 Creating application user..."
sudo useradd -r -s /bin/false go-book-api || echo "User already exists"

# Create application directories
echo "📁 Creating application directories..."
sudo mkdir -p /opt/go-book-api
sudo mkdir -p /var/log/go-book-api
sudo mkdir -p /etc/go-book-api

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R go-book-api:go-book-api /opt/go-book-api
sudo chown -R go-book-api:go-book-api /var/log/go-book-api
sudo chown -R go-book-api:go-book-api /etc/go-book-api

# Create log rotation configuration
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/go-book-api > /dev/null <<EOF
/var/log/go-book-api/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 go-book-api go-book-api
    postrotate
        systemctl reload go-book-api > /dev/null 2>&1 || true
    endscript
}
EOF

# Configure firewall (if ufw is installed)
if command -v ufw &> /dev/null; then
    echo "🔥 Configuring firewall..."
    sudo ufw allow 22/tcp   # SSH
    sudo ufw allow 8080/tcp # Application port
    echo "Firewall rules added for ports 22 and 8080"
fi

# Create nginx configuration template (optional)
echo "🌐 Creating nginx configuration template..."
sudo tee /etc/nginx/sites-available/go-book-api > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
EOF

echo "✅ Server setup completed!"
echo ""
echo "Next steps:"
echo "1. Configure your GitHub repository secrets:"
echo "   - SERVER_HOST: Your server IP address"
echo "   - SERVER_USER: Your SSH username (usually 'ubuntu')"
echo "   - SERVER_SSH_KEY: Your private SSH key"
echo "   - SERVER_PORT: SSH port (usually 22)"
echo ""
echo "2. If using nginx, enable the site:"
echo "   sudo ln -s /etc/nginx/sites-available/go-book-api /etc/nginx/sites-enabled/"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "3. Push to staging branch to trigger deployment!"
echo ""
echo "🔗 Your API will be available at: http://your-server-ip:8080"
echo "🏥 Health check: http://your-server-ip:8080/health"
