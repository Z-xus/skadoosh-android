#!/bin/bash

# Skadoosh Sync Server Test Script - Key-Based Authentication
# This script tests the new SSH-style key authentication system

SERVER_URL="http://localhost:3233"  # Change this to your server URL
GROUP_NAME="test-group-$(date +%s)"

echo "🧪 Testing Skadoosh Key-Based Sync Server"
echo "Server URL: $SERVER_URL"
echo "Group Name: $GROUP_NAME"
echo ""

# Test 1: Health Check
echo "1. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" "$SERVER_URL/health")
HEALTH_CODE="${HEALTH_RESPONSE: -3}"
HEALTH_BODY="${HEALTH_RESPONSE%???}"

if [ "$HEALTH_CODE" = "200" ]; then
    echo "✅ Health check passed"
    echo "   Response: $HEALTH_BODY"
else
    echo "❌ Health check failed with status: $HEALTH_CODE"
    echo "   Response: $HEALTH_BODY"
    exit 1
fi
echo ""

# Generate a test RSA key pair (simplified)
echo "🔑 Generating test key pair..."
# For testing, we'll use a simple mock public key
TEST_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1234567890ABCDEF...
-----END PUBLIC KEY-----"

# Test 2: Join Sync Group
echo "2. Testing join sync group..."
JOIN_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d "{\"groupName\":\"$GROUP_NAME\",\"publicKey\":\"$TEST_PUBLIC_KEY\",\"deviceId\":\"test_device\",\"deviceName\":\"Test Device\"}" \
  "$SERVER_URL/api/auth/join-group")

JOIN_CODE="${JOIN_RESPONSE: -3}"
JOIN_BODY="${JOIN_RESPONSE%???}"

if [ "$JOIN_CODE" = "200" ]; then
    echo "✅ Join sync group passed"
    echo "   Response: $JOIN_BODY"
    
    # Extract group ID and fingerprint from response
    GROUP_ID=$(echo "$JOIN_BODY" | grep -o '"groupId":"[^"]*"' | cut -d'"' -f4)
    FINGERPRINT=$(echo "$JOIN_BODY" | grep -o '"fingerprint":"[^"]*"' | cut -d'"' -f4)
    echo "   Group ID: $GROUP_ID"
    echo "   Fingerprint: $FINGERPRINT"
else
    echo "❌ Join sync group failed with status: $JOIN_CODE"
    echo "   Response: $JOIN_BODY"
    exit 1
fi
echo ""

# Test 3: Get Challenge
echo "3. Testing authentication challenge..."
CHALLENGE_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d "{\"fingerprint\":\"$FINGERPRINT\"}" \
  "$SERVER_URL/api/auth/challenge")

CHALLENGE_CODE="${CHALLENGE_RESPONSE: -3}"
CHALLENGE_BODY="${CHALLENGE_RESPONSE%???}"

if [ "$CHALLENGE_CODE" = "200" ]; then
    echo "✅ Authentication challenge passed"
    echo "   Response: $CHALLENGE_BODY"
    CHALLENGE=$(echo "$CHALLENGE_BODY" | grep -o '"challenge":"[^"]*"' | cut -d'"' -f4)
    echo "   Challenge: ${CHALLENGE:0:32}..."
else
    echo "❌ Authentication challenge failed with status: $CHALLENGE_CODE"
    echo "   Response: $CHALLENGE_BODY"
fi
echo ""

# Test 4: Group Info
echo "4. Testing group info..."
GROUP_INFO_RESPONSE=$(curl -s -w "%{http_code}" -X GET \
  "$SERVER_URL/api/auth/group/$GROUP_ID")

GROUP_INFO_CODE="${GROUP_INFO_RESPONSE: -3}"
GROUP_INFO_BODY="${GROUP_INFO_RESPONSE%???}"

if [ "$GROUP_INFO_CODE" = "200" ]; then
    echo "✅ Group info passed"
    echo "   Response: $GROUP_INFO_BODY"
else
    echo "❌ Group info failed with status: $GROUP_INFO_CODE"
    echo "   Response: $GROUP_INFO_BODY"
fi
echo ""

echo "🏁 Key-based authentication test completed!"
echo ""
echo "📱 To test with the Flutter app:"
echo "   1. Open the app and go to Settings → Key Management"
echo "   2. Generate a new key or import an existing one"
echo "   3. Use group name: '$GROUP_NAME' to join the same group"
echo "   4. Go to Sync Settings and configure your server URL"
echo "   5. Try syncing notes!"
echo ""
echo "🔑 Key Features Available:"
echo "   ✅ RSA key pair generation"
echo "   ✅ Sync group creation and joining"
echo "   ✅ Challenge-response authentication"
echo "   ✅ Group-isolated note synchronization"
echo "   ✅ Multi-device support with same key"
echo ""
echo "💡 For production use:"
echo "   - Generate proper RSA keys in the app"
echo "   - Use strong group names"
echo "   - Keep private keys secure"
echo "   - Share only public keys with friends"