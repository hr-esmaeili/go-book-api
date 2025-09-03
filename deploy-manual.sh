#!/bin/bash

# Manual deployment script for Go Book API
# This script helps with manual deployment using SSH password authentication

set -e

# Configuration
APP_NAME="go-book-api"
BUILD_DIR="bin"
DEPLOY_DIR="deploy"
TAR_FILE="${APP_NAME}.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting manual deployment of $APP_NAME...${NC}"

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo -e "${RED}Usage: $0 <server_host> <username> <server_path>${NC}"
    echo "Example: $0 192.168.1.100 ubuntu /tmp"
    exit 1
fi

SERVER_HOST=$1
USERNAME=$2
SERVER_PATH=$3

echo -e "${YELLOW}Deployment target: $USERNAME@$SERVER_HOST:$SERVER_PATH${NC}"

# Build the application
echo -e "${YELLOW}Building application...${NC}"
if [ ! -f "go.mod" ]; then
    echo -e "${RED}Error: go.mod not found. Please run this script from the project root.${NC}"
    exit 1
fi

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

# Upload to server
echo -e "${YELLOW}Uploading to server...${NC}"
echo "You will be prompted for your SSH password."

scp $TAR_FILE deploy.sh $USERNAME@$SERVER_HOST:$SERVER_PATH/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Upload successful!${NC}"
else
    echo -e "${RED}Upload failed!${NC}"
    exit 1
fi

# Deploy on server
echo -e "${YELLOW}Deploying on server...${NC}"
echo "You will be prompted for your SSH password again."

ssh $USERNAME@$SERVER_HOST "cd $SERVER_PATH && chmod +x deploy.sh && sudo ./deploy.sh"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}Your API should now be running on port 8080${NC}"
    echo -e "${YELLOW}Check status with: ssh $USERNAME@$SERVER_HOST 'sudo systemctl status $APP_NAME'${NC}"
else
    echo -e "${RED}Deployment failed!${NC}"
    exit 1
fi

# Cleanup
echo -e "${YELLOW}Cleaning up local files...${NC}"
rm -rf $DEPLOY_DIR
rm -f $TAR_FILE

echo -e "${GREEN}Manual deployment completed!${NC}"
