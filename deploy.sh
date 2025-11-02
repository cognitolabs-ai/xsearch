#!/bin/bash
# XSearch Quick Deploy Script
set -e

echo "========================================="
echo "XSearch by Cognitolabs AI - Quick Deploy"
echo "========================================="
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    echo "Please install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check for Docker Compose
if ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose v2 is not installed!"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env

    # Generate random secret
    SECRET=$(openssl rand -base64 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

    # Update secret in .env
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/CHANGE-ME-TO-RANDOM-SECRET-KEY/$SECRET/" .env
    else
        sed -i "s/CHANGE-ME-TO-RANDOM-SECRET-KEY/$SECRET/" .env
    fi

    echo "✓ Generated secure secret key"
    echo ""
    echo "IMPORTANT: Edit .env and set XSEARCH_BASE_URL to your public URL"
    echo "Example: XSEARCH_BASE_URL=https://search.example.com"
    echo ""
    read -p "Press Enter to continue with localhost setup, or Ctrl+C to edit .env first..."
fi

# Ask about caching
echo ""
read -p "Enable Valkey/Redis caching for better performance? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    PROFILE="--profile with-cache"
    echo "Starting XSearch with Valkey cache..."
else
    PROFILE=""
    echo "Starting XSearch without cache..."
fi

# Pull latest images
echo ""
echo "Pulling latest Docker images..."
docker compose $PROFILE pull

# Start services
echo ""
echo "Starting XSearch..."
docker compose $PROFILE up -d

# Wait for services to be ready
echo ""
echo "Waiting for XSearch to start..."
sleep 5

# Check if running
if docker compose ps | grep -q "xsearch.*Up"; then
    echo ""
    echo "========================================="
    echo "✓ XSearch is running!"
    echo "========================================="
    echo ""
    echo "Access XSearch at: http://localhost:8080"
    echo ""
    echo "View logs with: docker compose logs -f xsearch"
    echo "Stop with: docker compose down"
    echo ""
    echo "For production deployment, see DEPLOYMENT.md"
    echo "========================================="
else
    echo ""
    echo "ERROR: XSearch failed to start!"
    echo "Check logs with: docker compose logs xsearch"
    exit 1
fi
