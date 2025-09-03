# Deployment Guide

This guide explains how to deploy the Go Book API to an Ubuntu server using GitHub Actions.

## Prerequisites

### Server Requirements
- Ubuntu 20.04+ server
- MySQL 8.0+ installed and running
- SSH access with sudo privileges
- Go 1.21+ (if building on server)

### GitHub Repository Setup
You need to configure the following secrets in your GitHub repository:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `HOST` | Your server's IP address or domain | `192.168.1.100` or `api.yourdomain.com` |
| `USERNAME` | SSH username | `ubuntu` or `deploy` |
| `PASSWORD` | SSH password for authentication | `your_ssh_password` |
| `PORT` | SSH port (optional, defaults to 22) | `22` |
| `DB_PASSWORD` | MySQL root password | `your_secure_password` |

## Server Setup

### 1. Install MySQL
```bash
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
```

### 2. Create Database
```bash
sudo mysql -u root -p
```
```sql
CREATE DATABASE bookdb;
CREATE USER 'bookapi'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON bookdb.* TO 'bookapi'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Configure MySQL for Remote Connections (Optional)
Edit `/etc/mysql/mysql.conf.d/mysqld.cnf`:
```ini
bind-address = 0.0.0.0
```

Restart MySQL:
```bash
sudo systemctl restart mysql
```

### 4. Setup SSH Password Authentication
Ensure your server allows password authentication for SSH:

1. **Edit SSH configuration** (if needed):
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
   
   Make sure these settings are enabled:
   ```
   PasswordAuthentication yes
   PubkeyAuthentication yes
   ```

2. **Restart SSH service**:
   ```bash
   sudo systemctl restart ssh
   ```

3. **Add your SSH password to GitHub secrets as `PASSWORD`**.

## Deployment Methods

### Method 1: GitHub Actions (Recommended)

The deployment is automated through GitHub Actions. When you push to `main` or `develop` branches:

1. **Test Phase**: Runs tests and builds the application
2. **Deploy Phase**: 
   - Builds the application
   - Creates a deployment package
   - Uploads to server via SCP
   - Runs deployment script on server
   - Starts the service

### Method 2: Manual Deployment

#### Option A: Using the deployment script (Recommended)

Use the provided manual deployment script:

```bash
# Make the script executable
chmod +x deploy-manual.sh

# Run the deployment script
./deploy-manual.sh <server_host> <username> <server_path>

# Example:
./deploy-manual.sh 192.168.1.100 ubuntu /tmp
```

The script will:
- Build the application
- Create a deployment package
- Upload to server via SCP
- Deploy on server via SSH
- Clean up local files

#### Option B: Manual steps

1. **Build locally**:
   ```bash
   go build -o bin/go-book-api ./cmd
   ```

2. **Create deployment package**:
   ```bash
   mkdir -p deploy
   cp bin/go-book-api deploy/
   cp -r app deploy/
   cp go.mod deploy/
   cp go.sum deploy/
   tar -czf go-book-api.tar.gz -C deploy .
   ```

3. **Upload to server**:
   ```bash
   scp go-book-api.tar.gz deploy.sh username@your-server:/tmp/
   ```

4. **Deploy on server**:
   ```bash
   ssh username@your-server
   chmod +x /tmp/deploy.sh
   sudo /tmp/deploy.sh
   ```

   **Note**: You'll be prompted for your SSH password when using `scp` and `ssh` commands.

### Method 3: Docker Deployment

1. **Build and run with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

2. **Or build Docker image manually**:
   ```bash
   docker build -t go-book-api .
   docker run -d -p 8080:8080 --name go-book-api go-book-api
   ```

## Service Management

### Systemd Service Commands
```bash
# Check status
sudo systemctl status go-book-api

# Start service
sudo systemctl start go-book-api

# Stop service
sudo systemctl stop go-book-api

# Restart service
sudo systemctl restart go-book-api

# View logs
sudo journalctl -u go-book-api -f

# Enable auto-start
sudo systemctl enable go-book-api
```

### Service Configuration
The service is configured in `/etc/systemd/system/go-book-api.service`:

```ini
[Unit]
Description=Go Book API
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/go-book-api
ExecStart=/opt/go-book-api/go-book-api
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
```

## Nginx Configuration (Optional)

If you want to use Nginx as a reverse proxy:

1. **Install Nginx**:
   ```bash
   sudo apt install nginx
   ```

2. **Configure Nginx**:
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/go-book-api
   sudo ln -s /etc/nginx/sites-available/go-book-api /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

3. **SSL with Let's Encrypt**:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

## Monitoring and Logs

### Application Logs
```bash
# View recent logs
sudo journalctl -u go-book-api --no-pager -n 50

# Follow logs in real-time
sudo journalctl -u go-book-api -f

# View logs from specific time
sudo journalctl -u go-book-api --since "2024-01-01 00:00:00"
```

### Health Check
```bash
# Check if API is responding
curl http://localhost:8080/health

# Check from external
curl http://your-server-ip:8080/health
```

### Database Monitoring
```bash
# Check MySQL status
sudo systemctl status mysql

# Connect to database
mysql -u root -p bookdb

# Check tables
SHOW TABLES;
SELECT * FROM books;
```

## Troubleshooting

### Common Issues

1. **Service won't start**:
   ```bash
   sudo journalctl -u go-book-api --no-pager -n 20
   ```

2. **Database connection issues**:
   - Check MySQL is running: `sudo systemctl status mysql`
   - Verify credentials in service file
   - Test connection: `mysql -u root -p bookdb`

3. **Port already in use**:
   ```bash
   sudo netstat -tlnp | grep :8080
   sudo lsof -i :8080
   ```

4. **Permission issues**:
   ```bash
   sudo chown -R www-data:www-data /opt/go-book-api
   sudo chmod +x /opt/go-book-api/go-book-api
   ```

### Rollback
If you need to rollback to a previous version:

```bash
# List backups
ls -la /opt/backups/go-book-api/

# Restore from backup
sudo systemctl stop go-book-api
sudo cp /opt/backups/go-book-api/go-book-api.backup.YYYYMMDD_HHMMSS /opt/go-book-api/go-book-api
sudo systemctl start go-book-api
```

## Security Considerations

1. **Firewall**: Configure UFW to only allow necessary ports
2. **SSH**: Use strong passwords and consider key-based authentication for better security
3. **Database**: Use strong passwords and limit user privileges
4. **SSL**: Always use HTTPS in production
5. **Updates**: Keep the system and dependencies updated
6. **SSH Security**: Consider disabling root login and using non-standard ports

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `3306` | Database port |
| `DB_USER` | `root` | Database username |
| `DB_PASS` | - | Database password |
| `DB_NAME` | `bookdb` | Database name |
| `LOG_LEVEL` | `info` | Log level |
