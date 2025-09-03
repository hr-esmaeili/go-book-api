#!/bin/bash

# Docker-based deployment script for Go Book API
# This script uses Docker to avoid sudo issues

set -e

APP_NAME="go-book-api"
CONTAINER_NAME="$APP_NAME"
IMAGE_NAME="$APP_NAME:latest"

echo "Starting Docker deployment of $APP_NAME..."

# Stop and remove existing container if it exists
echo "Stopping and removing existing container..."
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# Build the Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME .

# Run the container
echo "Starting container..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 8080:8080 \
    -e PORT=8080 \
    -e DB_HOST=host.docker.internal \
    -e DB_PORT=3306 \
    -e DB_USER=root \
    -e DB_PASS=your_db_password \
    -e DB_NAME=bookdb \
    --restart unless-stopped \
    $IMAGE_NAME

# Wait a moment and check status
sleep 5
echo "Checking container status..."
docker ps | grep $CONTAINER_NAME

# Show recent logs
echo "Recent logs:"
docker logs $CONTAINER_NAME --tail 10

echo "Docker deployment completed successfully!"
echo "Service is running on port 8080"
echo "Check logs with: docker logs $CONTAINER_NAME -f"
echo "Stop service with: docker stop $CONTAINER_NAME"
