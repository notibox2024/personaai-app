#!/bin/bash

# Script to build custom images for PersonaAI Docker setup
# Usage: ./build-custom-images.sh

set -e

echo "🔧 Building Custom PersonaAI Docker Images"
echo "=========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the personaai-docker directory"
    exit 1
fi

echo "🏗️  Building custom Keycloak image with curl..."
docker build -f Dockerfile.keycloak -t personaai-keycloak:26.2 .

echo "✅ Custom images built successfully!"
echo ""
echo "📋 Built Images:"
echo "  - personaai-keycloak:26.2 (with curl for health checks)"
echo ""
echo "🚀 Next steps:"
echo "  docker-compose up -d"
echo ""
echo "🔍 Verify health check:"
echo "  docker-compose exec keycloak curl http://localhost:9000/health/ready" 