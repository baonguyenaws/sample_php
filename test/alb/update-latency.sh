#!/bin/bash

# Script để update latency của Cloud Run service và test alert policy
# Usage: ./update-latency.sh <LATENCY_MS>
# Example: ./update-latency.sh 4000  # Set to 4 seconds

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LATENCY_MS=${1:-100}

# Get variables from terraform
PROJECT_ID="rare-karma-480813-i3"
REGION="asia-southeast1"
SERVICE_NAME="app-service"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Cannot get terraform outputs${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}⚡ Updating Cloud Run Latency${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project:  $PROJECT_ID"
echo "  Region:   $REGION"
echo "  Service:  $SERVICE_NAME"
echo "  Latency:  ${LATENCY_MS}ms ($(echo "scale=1; $LATENCY_MS/1000" | bc)s)"
echo ""

# Update service
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --project $PROJECT_ID \
  --set-env-vars LATENCY_MS=$LATENCY_MS \
  --quiet

echo ""
echo -e "${GREEN}✅ Latency updated successfully!${NC}"
echo ""

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --project $PROJECT_ID \
  --format="value(status.url)")

echo -e "${YELLOW}Test the new latency:${NC}"
echo "  curl $SERVICE_URL/api/test"
echo ""

# Show recommendation
if [ $LATENCY_MS -gt 3000 ]; then
    echo -e "${YELLOW}⚠️  Latency > 3 seconds - This WILL trigger the alert policy!${NC}"
    echo "Expected behavior:"
    echo "  1. Generate traffic with test-load.sh"
    echo "  2. Wait 2-5 minutes for metrics to appear"
    echo "  3. Alert should trigger within 3-6 minutes"
    echo "  4. Email notification within 5-10 minutes"
else
    echo -e "${GREEN}✓ Latency ≤ 3 seconds - Normal operation${NC}"
fi
