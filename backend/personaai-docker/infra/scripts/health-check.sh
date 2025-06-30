#!/bin/bash

# Health check script for PersonaAI Docker services
# Usage: ./health-check.sh

set -e

KEYCLOAK_URL="http://localhost:9000"
POSTGREST_URL="http://localhost:3300"
REDIS_URL="localhost:6379"

echo "🏥 PersonaAI Docker Services Health Check"
echo "=========================================="

# Function to check service status
check_service() {
    local service_name=$1
    local check_command=$2
    local description=$3
    
    echo -n "Checking $service_name... "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo "✅ $description"
        return 0
    else
        echo "❌ $description"
        return 1
    fi
}

# Check Docker containers
echo "📦 Docker Containers Status:"
docker-compose ps

echo -e "\n🔍 Service Health Checks:"

# Check PostgreSQL
check_service "PostgreSQL" \
    "docker-compose exec -T postgres pg_isready -U postgres -d personaai" \
    "Database is ready"

# Check Redis
check_service "Redis" \
    "docker-compose exec -T redis redis-cli ping | grep -q PONG" \
    "Cache is responding"

# Check Keycloak
check_service "Keycloak" \
    "curl -s -f $KEYCLOAK_URL/health/ready" \
    "Identity server is ready"

# Check PostgREST
check_service "PostgREST" \
    "curl -s -f $POSTGREST_URL/" \
    "REST API is responding"

echo -e "\n🔗 Service URLs:"
echo "  - Keycloak Admin: http://localhost:8080"
echo "  - Keycloak Health: $KEYCLOAK_URL"
echo "  - PostgREST API: $POSTGREST_URL"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: $REDIS_URL"

echo -e "\n📊 Service Logs (last 10 lines):"
echo "================================="

for service in postgres redis keycloak postgrest; do
    echo -e "\n🔍 $service logs:"
    docker-compose logs --tail=10 $service 2>/dev/null || echo "No logs available for $service"
done

echo -e "\n🧪 Testing Keycloak health from inside container:"
docker-compose exec keycloak curl -s http://localhost:9000/health/ready | jq . 2>/dev/null || echo "jq not available, showing raw response:"
docker-compose exec keycloak curl -s http://localhost:9000/health/ready 2>/dev/null || echo "Could not connect to Keycloak health endpoint"

echo -e "\n✨ Health check completed!"
echo "If any service shows ❌, check the logs above or run:"
echo "  docker-compose logs [service-name]" 