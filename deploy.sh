#!/bin/bash
set -e
echo "Starting deployment..."
echo "Stopping existing Docker containers (if any)..."
docker-compose down
echo "Building and starting services..."
docker-compose up -d --build
echo "Waiting for services to start..."
sleep 5
echo "Service status:"
docker-compose ps
echo "Last 20 lines of chat server logs:"
docker-compose logs --tail=20 chat_server

echo ""
echo "Deployment completed successfully."
echo "Chat server running at: http://localhost:8080"
echo "MySQL is accessible at: localhost:3306"
echo ""
echo "To start the chat client, run:"
echo "lua client.lua"
echo "Made With <3 -harishannavisamy"