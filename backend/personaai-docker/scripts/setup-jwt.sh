#!/bin/bash

# Script to configure JWKS authentication between Keycloak and PostgREST
# Usage: ./setup-jwt.sh [realm_name]

set -e

REALM_NAME=${1:-personaai}
KEYCLOAK_URL="http://localhost:8080"  # Main Keycloak URL for API access
KEYCLOAK_HEALTH_URL="http://localhost:9000"  # Health check URL
POSTGREST_CONTAINER="personaai-postgrest"
JWKS_FILE="jwks.json"

echo "🔧 Setting up JWKS authentication for realm: $REALM_NAME"

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
timeout=60
while ! curl -s "$KEYCLOAK_HEALTH_URL/health/ready" > /dev/null; do
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "❌ Keycloak is not ready after 60 seconds"
        exit 1
    fi
    echo "Waiting for Keycloak... ($timeout seconds remaining)"
    sleep 1
done

echo "✅ Keycloak is ready"

# Fetch JWKS from Keycloak
echo "🔑 Fetching JWKS from Keycloak..."
JWKS_URL="$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/certs"

# Backup existing JWKS file if it exists
if [ -f "$JWKS_FILE" ]; then
    echo "💾 Backing up existing JWKS file..."
    cp "$JWKS_FILE" "$JWKS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Fetch and save JWKS
curl -s "$JWKS_URL" > "$JWKS_FILE" || {
    echo "❌ Failed to fetch JWKS from $JWKS_URL"
    echo "💡 Make sure realm '$REALM_NAME' exists and is properly configured."
    exit 1
}

# Validate JWKS format
if ! jq empty "$JWKS_FILE" 2>/dev/null; then
    echo "❌ Invalid JSON format in JWKS file"
    exit 1
fi

# Check if JWKS contains keys
KEY_COUNT=$(jq '.keys | length' "$JWKS_FILE" 2>/dev/null || echo "0")
if [ "$KEY_COUNT" -eq 0 ]; then
    echo "❌ No keys found in JWKS"
    exit 1
fi

echo "✅ JWKS fetched successfully with $KEY_COUNT key(s)"

# Display key information
echo "📋 JWKS Key Information:"
jq -r '.keys[] | "  - Key ID: \(.kid), Algorithm: \(.alg), Type: \(.kty)"' "$JWKS_FILE"

# Restart PostgREST container to reload JWKS
echo "🔄 Restarting PostgREST container..."
docker compose restart postgrest

# Wait for PostgREST to be ready
echo "⏳ Waiting for PostgREST to be ready..."
timeout=30
while ! curl -s "http://localhost:3000/" > /dev/null; do
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "⚠️  PostgREST may not be ready, but continuing..."
        break
    fi
    sleep 1
done

echo "✅ PostgREST restarted successfully"

# Verify JWKS is mounted correctly
echo "🔍 Verifying JWKS configuration..."
if docker exec "$POSTGREST_CONTAINER" cat /etc/postgrest/jwks.json > /dev/null 2>&1; then
    echo "✅ JWKS file is properly mounted in PostgREST container"
else
    echo "⚠️  Warning: Could not verify JWKS file in container"
fi

# Display configuration summary
echo "
🎉 JWKS Authentication Setup Complete!

📋 Configuration Summary:
- Realm: $REALM_NAME
- Keycloak URL: $KEYCLOAK_URL
- PostgREST URL: http://localhost:3000
- JWKS File: $JWKS_FILE
- Keys Found: $KEY_COUNT

🔧 Next Steps:
1. Create a client in Keycloak:
   - Client ID: postgrest
   - Client Type: confidential
   - Service accounts: enabled

2. Create users and roles in Keycloak

3. Test the setup:
   # Get token
   curl -X POST $KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token \\
     -H \"Content-Type: application/x-www-form-urlencoded\" \\
     -d \"grant_type=password\" \\
     -d \"client_id=postgrest\" \\
     -d \"client_secret=YOUR_CLIENT_SECRET\" \\
     -d \"username=YOUR_USERNAME\" \\
     -d \"password=YOUR_PASSWORD\"

   # Use token with PostgREST
   curl -H \"Authorization: Bearer YOUR_TOKEN\" \\
     http://localhost:3000/users

🔄 Key Rotation:
To rotate keys, simply run this script again:
./scripts/setup-jwt.sh $REALM_NAME

📚 See README.md for detailed configuration instructions.
"