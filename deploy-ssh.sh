#!/bin/bash

# SSH-based deployment script for Go Book API
# This script handles SSH password authentication and deploys to Ubuntu server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="go-book-api"
BUILD_DIR="bin"
DEPLOY_DIR="deploy"
TAR_FILE="${APP_NAME}.tar.gz"

echo -e "${GREEN}=== Go Book API SSH Deployment Script ===${NC}"
echo ""

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo -e "${RED}Usage: $0 <server_host> <username> <server_port> [deployment_method]${NC}"
    echo ""
    echo "Parameters:"
    echo "  server_host     - IP address or domain of your Ubuntu server"
    echo "  username        - SSH username"
    echo "  server_port     - SSH port (usually 22)"
    echo "  deployment_method - Optional: 'no-sudo', 'docker', 'simple' (default: no-sudo)"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100 ubuntu 22"
    echo "  $0 api.yourdomain.com deploy 2222 docker"
    echo ""
    exit 1
fi

SERVER_HOST=$1
USERNAME=$2
SERVER_PORT=$3
DEPLOYMENT_METHOD=${4:-"no-sudo"}

echo -e "${BLUE}Deployment Configuration:${NC}"
echo "  Server: $USERNAME@$SERVER_HOST:$SERVER_PORT"
echo "  Method: $DEPLOYMENT_METHOD"
echo ""

# Validate deployment method
if [[ ! "$DEPLOYMENT_METHOD" =~ ^(no-sudo|docker|simple)$ ]]; then
    echo -e "${RED}Error: Invalid deployment method '$DEPLOYMENT_METHOD'${NC}"
    echo "Valid methods: no-sudo, docker, simple"
    exit 1
fi

# Check if required files exist
if [ ! -f "go.mod" ]; then
    echo -e "${RED}Error: go.mod not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Install sshpass if not available (for password authentication)
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    elif command -v brew &> /dev/null; then
        brew install hudochenkov/sshpass/sshpass
    else
        echo -e "${RED}Error: Cannot install sshpass automatically. Please install it manually.${NC}"
        echo "Ubuntu/Debian: sudo apt-get install sshpass"
        echo "CentOS/RHEL: sudo yum install sshpass"
        echo "macOS: brew install hudochenkov/sshpass/sshpass"
        exit 1
    fi
fi

# Build the application
echo -e "${YELLOW}Building application...${NC}"
go build -o $BUILD_DIR/$APP_NAME ./cmd

if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo -e "${RED}Error: Build failed. Binary not found.${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Create deployment package
echo -e "${YELLOW}Creating deployment package...${NC}"
rm -rf $DEPLOY_DIR
mkdir -p $DEPLOY_DIR

# Copy necessary files
cp $BUILD_DIR/$APP_NAME $DEPLOY_DIR/
cp -r app $DEPLOY_DIR/
cp go.mod $DEPLOY_DIR/
cp go.sum $DEPLOY_DIR/
cp Makefile $DEPLOY_DIR/
cp README.md $DEPLOY_DIR/

# Create tar archive
tar -czf $TAR_FILE -C $DEPLOY_DIR .

echo -e "${GREEN}Deployment package created: $TAR_FILE${NC}"

# Prompt for SSH password
echo ""
echo -e "${BLUE}SSH Authentication:${NC}"
read -s -p "Enter SSH password for $USERNAME@$SERVER_HOST: " SSH_PASSWORD
echo ""

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $USERNAME@$SERVER_HOST "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${RED}Error: SSH connection failed. Please check your credentials and server details.${NC}"
    exit 1
fi

echo -e "${GREEN}SSH connection successful!${NC}"

# Upload files to server
echo -e "${YELLOW}Uploading files to server...${NC}"
sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT $TAR_FILE $USERNAME@$SERVER_HOST:/tmp/

# Upload the appropriate deployment script
DEPLOY_SCRIPT="deploy-${DEPLOYMENT_METHOD}.sh"
if [ -f "$DEPLOY_SCRIPT" ]; then
    sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT $DEPLOY_SCRIPT $USERNAME@$SERVER_HOST:/tmp/deploy.sh
else
    echo -e "${RED}Error: Deployment script $DEPLOY_SCRIPT not found.${NC}"
    exit 1
fi

echo -e "${GREEN}Files uploaded successfully!${NC}"

# Deploy on server
echo -e "${YELLOW}Deploying on server...${NC}"
sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $USERNAME@$SERVER_HOST "cd /tmp && chmod +x deploy.sh && ./deploy.sh"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=== Deployment Completed Successfully! ===${NC}"
    echo ""
    echo -e "${BLUE}Service Information:${NC}"
    echo "  Application: $APP_NAME"
    echo "  Server: $SERVER_HOST"
    echo "  Port: 8080"
    echo "  Deployment Method: $DEPLOYMENT_METHOD"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    case $DEPLOYMENT_METHOD in
        "no-sudo")
            echo "  Check status: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'systemctl --user status $APP_NAME'"
            echo "  View logs: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'journalctl --user -u $APP_NAME -f'"
            echo "  Stop service: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'systemctl --user stop $APP_NAME'"
            ;;
        "docker")
            echo "  Check status: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'docker ps | grep $APP_NAME'"
            echo "  View logs: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'docker logs $APP_NAME -f'"
            echo "  Stop service: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'docker stop $APP_NAME'"
            ;;
        "simple")
            echo "  Check status: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'ps aux | grep $APP_NAME'"
            echo "  View logs: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'tail -f ~/$APP_NAME/app.log'"
            echo "  Stop service: sshpass -p 'PASSWORD' ssh -p $SERVER_PORT $USERNAME@$SERVER_HOST 'kill \$(cat ~/$APP_NAME/$APP_NAME.pid)'"
            ;;
    esac
    echo ""
    echo -e "${GREEN}Test your API: curl http://$SERVER_HOST:8080/health${NC}"
else
    echo -e "${RED}Deployment failed!${NC}"
    exit 1
fi

# Cleanup
echo -e "${YELLOW}Cleaning up local files...${NC}"
rm -rf $DEPLOY_DIR
rm -f $TAR_FILE

echo -e "${GREEN}Deployment process completed!${NC}"
