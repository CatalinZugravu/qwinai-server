#!/bin/bash

# QwinAI Credit System Fix - Deployment Test Script
# Run this after deploying to Railway

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 QwinAI Credit System Fix - Deployment Test${NC}"
echo "=================================================="

# Check if RAILWAY_URL is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <RAILWAY_URL>${NC}"
    echo "Example: $0 https://yourapp.up.railway.app"
    exit 1
fi

RAILWAY_URL=$1
API_BASE="$RAILWAY_URL/api"

echo -e "${BLUE}Testing deployment at: $RAILWAY_URL${NC}"
echo

# Test 1: Health Check
echo -e "${YELLOW}🔍 Test 1: Health Check${NC}"
HEALTH_RESPONSE=$(curl -s -w "STATUS:%{http_code}" "$RAILWAY_URL/health")
HTTP_STATUS=$(echo "$HEALTH_RESPONSE" | grep -o "STATUS:[0-9]*" | cut -d: -f2)

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed (Status: $HTTP_STATUS)${NC}"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# Test 2: New User Credit Test
echo -e "${YELLOW}🔍 Test 2: New User Credits (Should be 15 chat, 20 image)${NC}"
NEW_USER_RESPONSE=$(curl -s "$API_BASE/user-state/TESTUSER12345?fingerprint=testfingerprint123")
CHAT_CREDITS=$(echo "$NEW_USER_RESPONSE" | grep -o '"availableChatCredits":[0-9]*' | cut -d: -f2)
IMAGE_CREDITS=$(echo "$NEW_USER_RESPONSE" | grep -o '"availableImageCredits":[0-9]*' | cut -d: -f2)

if [ "$CHAT_CREDITS" = "15" ] && [ "$IMAGE_CREDITS" = "20" ]; then
    echo -e "${GREEN}✅ New user credits correct: Chat=$CHAT_CREDITS, Image=$IMAGE_CREDITS${NC}"
else
    echo -e "${RED}❌ New user credits wrong: Chat=$CHAT_CREDITS, Image=$IMAGE_CREDITS${NC}"
    echo "Expected: Chat=15, Image=20"
    echo "Response: $NEW_USER_RESPONSE"
fi

# Test 3: Credit Consumption
echo -e "${YELLOW}🔍 Test 3: Credit Consumption${NC}"
CONSUME_RESPONSE=$(curl -s -X POST "$API_BASE/user-state/TESTUSER12345/consume-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "creditType": "chat",
    "amount": 3,
    "fingerprint": "testfingerprint123"
  }')

SUCCESS=$(echo "$CONSUME_RESPONSE" | grep -o '"success":true')
AVAILABLE=$(echo "$CONSUME_RESPONSE" | grep -o '"availableCredits":[0-9]*' | cut -d: -f2)

if [ -n "$SUCCESS" ] && [ "$AVAILABLE" = "12" ]; then
    echo -e "${GREEN}✅ Credit consumption works: $AVAILABLE remaining${NC}"
else
    echo -e "${RED}❌ Credit consumption failed${NC}"
    echo "Response: $CONSUME_RESPONSE"
fi

# Test 4: Reinstall Detection
echo -e "${YELLOW}🔍 Test 4: Reinstall Detection${NC}"
REINSTALL_RESPONSE=$(curl -s -X POST "$API_BASE/user-state/NEWDEVICE567/consume-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "creditType": "chat",
    "amount": 1,
    "fingerprint": "testfingerprint123"
  }')

REINSTALL_SUCCESS=$(echo "$REINSTALL_RESPONSE" | grep -o '"success":true')
REINSTALL_AVAILABLE=$(echo "$REINSTALL_RESPONSE" | grep -o '"availableCredits":[0-9]*' | cut -d: -f2)

if [ -n "$REINSTALL_SUCCESS" ] && [ "$REINSTALL_AVAILABLE" = "11" ]; then
    echo -e "${GREEN}✅ Reinstall detection works: Found existing user, $REINSTALL_AVAILABLE remaining${NC}"
else
    echo -e "${RED}❌ Reinstall detection failed${NC}"
    echo "Response: $REINSTALL_RESPONSE"
fi

# Test 5: Ad Credits
echo -e "${YELLOW}🔍 Test 5: Ad Credits${NC}"
AD_RESPONSE=$(curl -s -X POST "$API_BASE/user-state/TESTUSER12345/add-ad-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "creditType": "chat",
    "fingerprint": "testfingerprint123"
  }')

AD_SUCCESS=$(echo "$AD_RESPONSE" | grep -o '"success":true')

if [ -n "$AD_SUCCESS" ]; then
    echo -e "${GREEN}✅ Ad credits system works${NC}"
else
    echo -e "${RED}❌ Ad credits system failed${NC}"
    echo "Response: $AD_RESPONSE"
fi

echo
echo -e "${BLUE}🎉 Deployment Testing Complete!${NC}"
echo
echo -e "${YELLOW}📱 Next Steps:${NC}"
echo "1. Update Android app UserStateManager.kt:"
echo "   SERVER_BASE_URL = \"$API_BASE/\""
echo "2. Build and test your Android app"
echo "3. Verify credits work properly in production"
echo
echo -e "${GREEN}✅ Your credit abuse prevention system is deployed!${NC}"