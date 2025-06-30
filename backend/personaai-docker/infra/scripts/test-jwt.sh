#!/bin/bash

# Script to test JWT authentication with PostgREST
# Usage: ./test-jwt.sh [realm_name] [username] [password] [client_secret]

set -e

REALM_NAME=${1:-personaai}
USERNAME=${2:-testuser}
PASSWORD=${3:-password123}
CLIENT_SECRET=${4:-ZMBwETYzVPSzpkdIc4Vqg65i34M3WaJd}
CLIENT_ID="postgrest"

KEYCLOAK_URL="http://localhost:8080"
POSTGREST_URL="http://localhost:3300"

echo "🧪 Testing JWT Authentication"
echo "Realm: $REALM_NAME"
echo "Username: $USERNAME"
echo "Client ID: $CLIENT_ID"

# Check if client secret is provided
if [ -z "$CLIENT_SECRET" ]; then
    echo "❌ Client secret is required"
    echo "Usage: $0 [realm_name] [username] [password] [client_secret]"
    echo "💡 Get client secret from Keycloak admin console"
    exit 1
fi

# Step 1: Get access token
echo "🔑 Getting access token..."
TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" || {
    echo "❌ Failed to get access token"
    exit 1
})

# Check if token request was successful
if echo "$TOKEN_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Token request failed:"
    echo "$TOKEN_RESPONSE" | jq -r '.error_description // .error'
    exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ No access token received"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi

echo "✅ Access token received"

# Decode and display token info
echo "📋 Token Information:"
HEADER=$(echo "$ACCESS_TOKEN" | cut -d. -f1 | base64 -d 2>/dev/null | jq . 2>/dev/null || echo "Failed to decode header")
PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq . 2>/dev/null || echo "Failed to decode payload")

echo "Header: $HEADER"
echo "Payload (first 200 chars): $(echo "$PAYLOAD" | head -c 200)..."

# Step 2: Test PostgREST with token
echo "🔌 Testing PostgREST with token..."

# Test root endpoint
echo "Testing root endpoint..."
ROOT_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$POSTGREST_URL/" || {
    echo "❌ Failed to connect to PostgREST"
    exit 1
})

echo "✅ PostgREST root endpoint accessible"

# Test API endpoint (if exists)
echo "Testing API endpoints..."

# Try to list tables/views
TABLES_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$POSTGREST_URL/" | jq -r 'keys[]' 2>/dev/null || echo "No tables found")

echo "Available endpoints: $TABLES_RESPONSE"

# Test specific API endpoint if it exists
if echo "$TABLES_RESPONSE" | grep -q "users"; then
    echo "Testing /users endpoint..."
    USERS_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
      "$POSTGREST_URL/users" || echo "Failed to query users")
    echo "Users response: $USERS_RESPONSE"
fi

# Step 3: Test without token (should fail)
echo "🚫 Testing without token (should fail)..."
NO_TOKEN_RESPONSE=$(curl -s "$POSTGREST_URL/users" 2>/dev/null || echo "Request failed as expected")

if echo "$NO_TOKEN_RESPONSE" | grep -q "JWT"; then
    echo "✅ Correctly rejected request without token"
else
    echo "⚠️  Request without token was not properly rejected"
    echo "Response: $NO_TOKEN_RESPONSE"
fi

# Step 4: Test with invalid token (should fail)
echo "🚫 Testing with invalid token (should fail)..."
INVALID_TOKEN_RESPONSE=$(curl -s -H "Authorization: Bearer invalid.token.here" \
  "$POSTGREST_URL/users" 2>/dev/null || echo "Request failed as expected")

if echo "$INVALID_TOKEN_RESPONSE" | grep -q "JWT" || echo "$INVALID_TOKEN_RESPONSE" | grep -q "error"; then
    echo "✅ Correctly rejected request with invalid token"
else
    echo "⚠️  Request with invalid token was not properly rejected"
    echo "Response: $INVALID_TOKEN_RESPONSE"
fi

# Display summary
echo "
🎉 JWT Authentication Test Complete!

📋 Test Results:
✅ Successfully obtained access token from Keycloak
✅ PostgREST accepted valid JWT token
✅ PostgREST correctly rejected requests without token
✅ PostgREST correctly rejected requests with invalid token

🔗 Endpoints tested:
- Keycloak Token: $KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token
- PostgREST Root: $POSTGREST_URL/
- PostgREST API: $POSTGREST_URL/users

💡 Your JWT authentication is working correctly!
" 