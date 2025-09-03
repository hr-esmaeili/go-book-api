# SSH Deployment Guide for Go Book API

This guide will help you deploy the Go Book API to your Ubuntu server using SSH with username and password authentication.

## Prerequisites

### Local Machine Requirements
- Go 1.21+ installed
- SSH client
- `sshpass` utility (for password authentication)

### Server Requirements
- Ubuntu 20.04+ server
- SSH access with username/password
- MySQL 8.0+ (for database)
- Docker (optional, for Docker deployment method)

## Quick Start

### 1. Install sshpass (if not already installed)

**Ubuntu/Debian:**
```bash
sudo apt-get update && sudo apt-get install sshpass
```

**CentOS/RHEL:**
```bash
sudo yum install sshpass
```

**macOS:**
```bash
brew install hudochenkov/sshpass/sshpass
```

### 2. Run the Deployment Script

```bash
# Make the script executable
chmod +x deploy-ssh.sh

# Deploy using no-sudo method (recommended)
./deploy-ssh.sh <server_ip> <username> <ssh_port>

# Example:
./deploy-ssh.sh 192.168.1.100 ubuntu 22
```

The script will:
1. Build the application locally
2. Create a deployment package
3. Prompt for your SSH password
4. Upload files to the server
5. Deploy the application
6. Provide you with management commands

## Deployment Methods

### Method 1: No-Sudo Deployment (Recommended)
- **Command:** `./deploy-ssh.sh <server> <user> <port> no-sudo`
- **Description:** Uses user-level systemd services
- **Pros:** No sudo required, easy to manage
- **Cons:** Service won't start on boot unless configured

### Method 2: Docker Deployment
- **Command:** `./deploy-ssh.sh <server> <user> <port> docker`
- **Description:** Uses Docker containers
- **Pros:** Isolated environment, easy to manage
- **Cons:** Requires Docker on server

### Method 3: Simple Binary Deployment
- **Command:** `./deploy-ssh.sh <server> <user> <port> simple`
- **Description:** Runs binary directly with PID file
- **Pros:** Simplest approach, no system services
- **Cons:** Less robust, no automatic restart

## GitHub Actions Integration

The project includes automated deployment via GitHub Actions. The workflow supports all three deployment methods and can be triggered automatically or manually.

### Automatic Deployment
- **Triggers:** Push to `main` or `develop` branches
- **Default Method:** No-sudo deployment
- **Process:** Runs tests → Builds application → Deploys to server

### Manual Deployment
You can manually trigger deployment with different methods:

1. Go to your GitHub repository
2. Click on "Actions" tab
3. Select "Deploy to Ubuntu Server" workflow
4. Click "Run workflow"
5. Choose your deployment method:
   - `no-sudo` (default)
   - `docker`
   - `simple`

### Required GitHub Secrets
Configure these secrets in your repository settings:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `HOST` | Your server's IP address or domain | `192.168.1.100` or `api.yourdomain.com` |
| `USERNAME` | SSH username | `ubuntu` or `deploy` |
| `PASSWORD` | SSH password for authentication | `your_ssh_password` |
| `PORT` | SSH port (optional, defaults to 22) | `22` |

### Setting up GitHub Secrets
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret with the exact names listed above
4. Save the secrets

### GitHub Actions Features
- ✅ **Automated Testing:** Runs tests before deployment
- ✅ **Multiple Deployment Methods:** Choose between no-sudo, Docker, or simple
- ✅ **Deployment Verification:** Automatically verifies deployment success
- ✅ **Health Checks:** Tests API endpoints after deployment
- ✅ **Manual Triggers:** Deploy on-demand with custom parameters

## Server Setup (First Time Only)

### 1. Install MySQL
```bash
# Connect to your server
ssh username@your-server-ip

# Install MySQL
sudo apt update
sudo apt install mysql-server

# Secure MySQL installation
sudo mysql_secure_installation
```

### 2. Create Database
```bash
# Connect to MySQL
sudo mysql -u root -p

# Create database and user
CREATE DATABASE bookdb;
CREATE USER 'bookapi'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON bookdb.* TO 'bookapi'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Configure SSH (if needed)
Ensure your server allows password authentication:

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Make sure these are enabled:
PasswordAuthentication yes
PubkeyAuthentication yes

# Restart SSH
sudo systemctl restart ssh
```

## Deployment Examples

### Example 1: Basic Deployment
```bash
./deploy-ssh.sh 192.168.1.100 ubuntu 22
```

### Example 2: Custom Port
```bash
./deploy-ssh.sh api.yourdomain.com deploy 2222
```

### Example 3: Docker Deployment
```bash
./deploy-ssh.sh 192.168.1.100 ubuntu 22 docker
```

## Post-Deployment Management

### Check Service Status

**No-Sudo Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'systemctl --user status go-book-api'
```

**Docker Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'docker ps | grep go-book-api'
```

**Simple Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'ps aux | grep go-book-api'
```

### View Logs

**No-Sudo Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'journalctl --user -u go-book-api -f'
```

**Docker Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'docker logs go-book-api -f'
```

**Simple Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'tail -f ~/go-book-api/app.log'
```

### Stop Service

**No-Sudo Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'systemctl --user stop go-book-api'
```

**Docker Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'docker stop go-book-api'
```

**Simple Method:**
```bash
sshpass -p 'your_password' ssh username@server-ip 'kill $(cat ~/go-book-api/go-book-api.pid)'
```

## Testing the Deployment

### 1. Health Check
```bash
curl http://your-server-ip:8080/health
```

### 2. API Endpoints
```bash
# Get all books
curl http://your-server-ip:8080/api/books

# Create a book
curl -X POST http://your-server-ip:8080/api/books \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Book","author":"Test Author","isbn":"1234567890"}'
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Check server IP and port
   - Verify username and password
   - Ensure SSH service is running on server

2. **Build Failed**
   - Ensure Go is installed locally
   - Check go.mod file exists
   - Verify all dependencies are available

3. **Service Won't Start**
   - Check logs for errors
   - Verify database connection
   - Ensure port 8080 is available

4. **Database Connection Issues**
   - Verify MySQL is running
   - Check database credentials
   - Ensure database exists

### Enable Auto-Start (No-Sudo Method)

To make the service start automatically on boot:

```bash
sshpass -p 'your_password' ssh username@server-ip 'loginctl enable-linger $USER'
```

## Security Considerations

1. **Change Default Passwords**
   - Update database passwords
   - Use strong SSH passwords

2. **Firewall Configuration**
   ```bash
   # Allow SSH
   sudo ufw allow 22
   
   # Allow API port
   sudo ufw allow 8080
   
   # Enable firewall
   sudo ufw enable
   ```

3. **SSL/HTTPS Setup**
   - Use Nginx as reverse proxy
   - Configure Let's Encrypt SSL certificates

## Environment Variables

The application uses these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `3306` | Database port |
| `DB_USER` | `root` | Database username |
| `DB_PASS` | - | Database password |
| `DB_NAME` | `bookdb` | Database name |

## Rollback

If you need to rollback to a previous version:

1. **Stop current service**
2. **Restore from backup** (if using no-sudo method, backups are in `~/backups/go-book-api/`)
3. **Restart service**

## Support

For issues or questions:
1. Check the logs first
2. Verify all prerequisites are met
3. Test SSH connection manually
4. Check server resources (disk space, memory)

## Next Steps

After successful deployment:
1. Set up monitoring
2. Configure backups
3. Set up SSL certificates
4. Configure load balancing (if needed)
5. Set up CI/CD pipeline
