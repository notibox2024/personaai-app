#!/bin/bash

# Script to rotate JWKS keys from Keycloak
# Usage: ./rotate-jwks.sh [realm_name]

set -e

REALM_NAME=${1:-personaai}
KEYCLOAK_URL="http://localhost:8080"
KEYCLOAK_HEALTH_URL="http://localhost:9000"
POSTGREST_CONTAINER="personaai-postgrest"
JWKS_FILE="jwks.json"
BACKUP_DIR="jwks-backups"

echo "🔄 JWKS Key Rotation for realm: $REALM_NAME"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if Keycloak is running
echo "⏳ Checking Keycloak availability..."
if ! curl -s "$KEYCLOAK_HEALTH_URL/health/ready" > /dev/null; then
    echo "❌ Keycloak is not ready. Please start Keycloak first."
    exit 1
fi

echo "✅ Keycloak is ready"

# Backup current JWKS
if [ -f "$JWKS_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/jwks-$(date +%Y%m%d_%H%M%S).json"
    echo "💾 Backing up current JWKS to: $BACKUP_FILE"
    cp "$JWKS_FILE" "$BACKUP_FILE"
    
    # Show current key info
    echo "📋 Current JWKS Key Information:"
    jq -r '.keys[] | "  - Key ID: \(.kid), Algorithm: \(.alg), Type: \(.kty)"' "$JWKS_FILE"
else
    echo "⚠️  No existing JWKS file found"
fi

# Fetch new JWKS
echo "🔑 Fetching new JWKS from Keycloak..."
JWKS_URL="$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/certs"

# Get new JWKS
curl -s "$JWKS_URL" > "$JWKS_FILE.new" || {
    echo "❌ Failed to fetch new JWKS from $JWKS_URL"
    exit 1
}

# Validate new JWKS format
if ! jq empty "$JWKS_FILE.new" 2>/dev/null; then
    echo "❌ Invalid JSON format in new JWKS"
    rm -f "$JWKS_FILE.new"
    exit 1
fi

# Check if new JWKS contains keys
NEW_KEY_COUNT=$(jq '.keys | length' "$JWKS_FILE.new" 2>/dev/null || echo "0")
if [ "$NEW_KEY_COUNT" -eq 0 ]; then
    echo "❌ No keys found in new JWKS"
    rm -f "$JWKS_FILE.new"
    exit 1
fi

# Compare old and new JWKS
if [ -f "$JWKS_FILE" ]; then
    OLD_KEYS=$(jq -r '.keys[].kid' "$JWKS_FILE" | sort)
    NEW_KEYS=$(jq -r '.keys[].kid' "$JWKS_FILE.new" | sort)
    
    if [ "$OLD_KEYS" = "$NEW_KEYS" ]; then
        echo "ℹ️  No key changes detected. JWKS is already up to date."
        rm -f "$JWKS_FILE.new"
        exit 0
    else
        echo "🔄 Key changes detected:"
        echo "Old keys: $OLD_KEYS"
        echo "New keys: $NEW_KEYS"
    fi
fi

# Replace old JWKS with new one
mv "$JWKS_FILE.new" "$JWKS_FILE"

echo "✅ JWKS updated successfully with $NEW_KEY_COUNT key(s)"

# Display new key information
echo "📋 New JWKS Key Information:"
jq -r '.keys[] | "  - Key ID: \(.kid), Algorithm: \(.alg), Type: \(.kty)"' "$JWKS_FILE"

# Restart PostgREST to reload JWKS
echo "🔄 Restarting PostgREST to reload JWKS..."
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

# Verify JWKS is loaded
echo "🔍 Verifying JWKS in PostgREST container..."
if docker exec "$POSTGREST_CONTAINER" cat /etc/postgrest/jwks.json > /dev/null 2>&1; then
    CONTAINER_KEY_COUNT=$(docker exec "$POSTGREST_CONTAINER" cat /etc/postgrest/jwks.json | jq '.keys | length')
    if [ "$CONTAINER_KEY_COUNT" = "$NEW_KEY_COUNT" ]; then
        echo "✅ JWKS successfully loaded in PostgREST container"
    else
        echo "⚠️  Warning: Key count mismatch in container ($CONTAINER_KEY_COUNT vs $NEW_KEY_COUNT)"
    fi
else
    echo "⚠️  Warning: Could not verify JWKS in container"
fi

# Clean up old backups (keep last 10)
echo "🧹 Cleaning up old backups..."
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/jwks-*.json 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 10 ]; then
        REMOVE_COUNT=$((BACKUP_COUNT - 10))
        ls -1t "$BACKUP_DIR"/jwks-*.json | tail -n "$REMOVE_COUNT" | xargs rm -f
        echo "🗑️  Removed $REMOVE_COUNT old backup(s)"
    fi
fi

echo "
🎉 JWKS Key Rotation Complete!

📋 Summary:
- Realm: $REALM_NAME
- Keys rotated: $NEW_KEY_COUNT
- Backup created: $BACKUP_FILE
- PostgREST restarted: ✅

🧪 Next steps:
1. Test the new keys:
   ./scripts/test-jwt.sh $REALM_NAME testuser password123 YOUR_CLIENT_SECRET

2. Monitor PostgREST logs:
   docker-compose logs -f postgrest

3. If issues occur, restore from backup:
   cp $BACKUP_FILE $JWKS_FILE
   docker-compose restart postgrest
" 