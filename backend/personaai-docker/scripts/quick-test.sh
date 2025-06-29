#!/bin/bash

# Quick test script to verify PersonaAI Docker setup
# Usage: ./quick-test.sh

set -e

echo "🧪 PersonaAI Docker Quick Test"
echo "==============================="

# Test external health checks
echo "🔍 Testing external health checks..."

echo "📡 PostgreSQL:"
if docker-compose exec -T postgres pg_isready -U postgres -d personaai > /dev/null 2>&1; then
    echo "  ✅ PostgreSQL is ready"
else
    echo "  ❌ PostgreSQL is not ready"
fi

echo "📡 Redis:"
if docker-compose exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo "  ✅ Redis is ready"
else
    echo "  ❌ Redis is not ready"
fi

echo "📡 Keycloak (from host):"
if curl -s -f http://localhost:9000/health/ready > /dev/null 2>&1; then
    echo "  ✅ Keycloak health endpoint is accessible"
    echo "  📋 Health status:"
    curl -s http://localhost:9000/health/ready | jq . 2>/dev/null || curl -s http://localhost:9000/health/ready
else
    echo "  ❌ Keycloak health endpoint is not accessible"
fi

echo "📡 Keycloak (from container):"
if docker-compose exec -T keycloak curl -s -f http://localhost:9000/health/ready > /dev/null 2>&1; then
    echo "  ✅ Keycloak internal health check works"
else
    echo "  ❌ Keycloak internal health check failed"
fi

echo "📡 PostgREST:"
if curl -s -f http://localhost:3000/ > /dev/null 2>&1; then
    echo "  ✅ PostgREST is ready"
else
    echo "  ❌ PostgREST is not ready"
fi

# Test JWKS configuration
echo ""
echo "🔐 Testing JWKS Configuration..."

echo "📋 JWKS File:"
if [ -f "jwks.json" ]; then
    echo "  ✅ JWKS file exists"
    KEY_COUNT=$(jq '.keys | length' jwks.json 2>/dev/null || echo "0")
    echo "  📊 Keys found: $KEY_COUNT"
    if [ "$KEY_COUNT" -gt 0 ]; then
        echo "  🔑 Key details:"
        jq -r '.keys[] | "    - Key ID: \(.kid), Algorithm: \(.alg), Type: \(.kty)"' jwks.json 2>/dev/null || echo "    Failed to parse key details"
    fi
else
    echo "  ⚠️  JWKS file not found - run ./scripts/setup-jwt.sh first"
fi

echo "📋 JWKS in PostgREST Container:"
if docker exec personaai-postgrest cat /etc/postgrest/jwks.json > /dev/null 2>&1; then
    echo "  ✅ JWKS file is mounted in PostgREST container"
    CONTAINER_KEY_COUNT=$(docker exec personaai-postgrest cat /etc/postgrest/jwks.json | jq '.keys | length' 2>/dev/null || echo "0")
    echo "  📊 Container keys: $CONTAINER_KEY_COUNT"
else
    echo "  ❌ JWKS file not accessible in PostgREST container"
fi

echo "📋 Keycloak Realm Check:"
REALM_NAME="personaai"
if curl -s "http://localhost:8080/realms/$REALM_NAME" > /dev/null 2>&1; then
    echo "  ✅ Keycloak realm '$REALM_NAME' is accessible"
    # Test JWKS endpoint
    if curl -s "http://localhost:8080/realms/$REALM_NAME/protocol/openid-connect/certs" > /dev/null 2>&1; then
        echo "  ✅ JWKS endpoint is accessible"
        REMOTE_KEY_COUNT=$(curl -s "http://localhost:8080/realms/$REALM_NAME/protocol/openid-connect/certs" | jq '.keys | length' 2>/dev/null || echo "0")
        echo "  📊 Remote keys: $REMOTE_KEY_COUNT"
    else
        echo "  ❌ JWKS endpoint is not accessible"
    fi
else
    echo "  ⚠️  Keycloak realm '$REALM_NAME' not found - create it first"
fi

echo ""
echo "🌐 Service URLs:"
echo "  - Keycloak Admin: http://localhost:8080"
echo "  - Keycloak Health: http://localhost:9000/health/ready"
echo "  - PostgREST API: http://localhost:3000"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - JWKS Endpoint: http://localhost:8080/realms/$REALM_NAME/protocol/openid-connect/certs"

echo ""
echo "🐳 Container Status:"
docker-compose ps

echo ""
echo "💾 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "🚀 Next Steps:"
if [ ! -f "jwks.json" ]; then
    echo "  1. Setup JWKS: ./scripts/setup-jwt.sh $REALM_NAME"
fi
echo "  2. Test JWT auth: ./scripts/test-jwt.sh $REALM_NAME username password client_secret"
echo "  3. Rotate keys: ./scripts/rotate-jwks.sh $REALM_NAME"

echo ""
echo "✨ Quick test completed!" 