# Deployment Guide - Password Authentication

This guide explains how to set up automated deployment using SSH with username and password authentication.

## Prerequisites

### 1. Server Requirements
- Ubuntu server (18.04 or later)
- SSH server enabled
- User with sudo privileges
- Port 8080 available for the application

### 2. GitHub Repository Setup

#### Configure GitHub Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SERVER_HOST` | Your server IP address or domain | `192.168.1.100` or `your-server.com` |
| `SERVER_USER` | SSH username | `ubuntu` or `your-username` |
| `SERVER_PASSWORD` | SSH password | `your-secure-password` |
| `SERVER_PORT` | SSH port | `22` (default) |

#### How to Add Secrets:
1. Go to your repository on GitHub
2. Click on "Settings" tab
3. In the left sidebar, click "Secrets and variables" → "Actions"
4. Click "New repository secret"
5. Add each secret with the exact name and value

## Server Setup

### 1. Initial Server Preparation

SSH into your server and run the setup script:

```bash
# SSH into your server
ssh your-username@your-server-ip

# Download and run the setup script
curl -O https://raw.githubusercontent.com/your-username/go-book-api/staging/deploy/setup-server.sh
chmod +x setup-server.sh
./setup-server.sh
```

### 2. Manual Server Setup (Alternative)

If you prefer to set up manually:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git unzip

# Create application user
sudo useradd -r -s /bin/false go-book-api

# Create directories
sudo mkdir -p /opt/go-book-api
sudo mkdir -p /var/log/go-book-api
sudo mkdir -p /etc/go-book-api

# Set permissions
sudo chown -R go-book-api:go-book-api /opt/go-book-api
sudo chown -R go-book-api:go-book-api /var/log/go-book-api
sudo chown -R go-book-api:go-book-api /etc/go-book-api

# Configure firewall (if ufw is installed)
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 8080/tcp # Application port
```

## Deployment Process

### Automated Deployment

1. **Push to staging branch:**
```bash
git checkout staging
git push origin staging
```

2. **Monitor deployment:**
   - Go to your GitHub repository
   - Click on "Actions" tab
   - Watch the deployment progress

### Manual Deployment (Alternative)

If you need to deploy manually:

```bash
# Build the application
go build -o go-book-api .

# Copy files to server
scp go-book-api your-username@your-server:/opt/go-book-api/
scp deploy/go-book-api.service your-username@your-server:/tmp/
scp deploy/env.production your-username@your-server:/opt/go-book-api/.env

# Setup service on server
ssh your-username@your-server
sudo cp /tmp/go-book-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable go-book-api
sudo systemctl start go-book-api
```

## Verification

### 1. Check Service Status
```bash
sudo systemctl status go-book-api
```

### 2. Test Health Endpoint
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### 3. Test API Endpoints
```bash
# Get all books
curl http://your-server-ip:8080/books

# Create a new book
curl -X POST http://your-server-ip:8080/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Book",
    "author": "Test Author",
    "isbn": "1234567890",
    "published_at": "2024-01-01T00:00:00Z"
  }'
```

## Troubleshooting

### Common Issues

#### 1. SSH Connection Failed
- Verify `SERVER_HOST`, `SERVER_USER`, and `SERVER_PASSWORD` secrets
- Check if SSH service is running on the server
- Ensure the user has sudo privileges

#### 2. Service Won't Start
```bash
# Check service logs
sudo journalctl -u go-book-api -f

# Check if port is in use
sudo netstat -tlnp | grep :8080
```

#### 3. Permission Denied
```bash
# Fix permissions
sudo chown -R go-book-api:go-book-api /opt/go-book-api
sudo chmod +x /opt/go-book-api/go-book-api
```

#### 4. Health Check Fails
```bash
# Check if service is running
sudo systemctl status go-book-api

# Test locally on server
curl http://localhost:8080/health
```

### Rollback

If deployment fails, you can rollback:

```bash
# On your server
curl -O https://raw.githubusercontent.com/your-username/go-book-api/staging/deploy/rollback.sh
chmod +x rollback.sh
./rollback.sh
```

## Security Considerations

### 1. Password Security
- Use a strong, unique password for your server user
- Consider using SSH keys for better security (optional)
- Regularly rotate passwords

### 2. Server Security
- Keep your server updated
- Use a firewall
- Consider using a non-standard SSH port
- Disable root login if possible

### 3. Application Security
- The application runs as a non-root user
- Systemd service includes security restrictions
- CORS is configured for cross-origin requests

## Monitoring

### 1. Service Logs
```bash
# View recent logs
sudo journalctl -u go-book-api --since "1 hour ago"

# Follow logs in real-time
sudo journalctl -u go-book-api -f
```

### 2. Health Monitoring
Set up monitoring to check the health endpoint regularly:
```bash
# Simple health check script
#!/bin/bash
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "Service is healthy"
else
    echo "Service is down!"
    # Add notification logic here
fi
```

## Next Steps

1. Set up a reverse proxy (nginx) for production
2. Configure SSL/TLS certificates
3. Set up monitoring and alerting
4. Implement database persistence
5. Add authentication and authorization
