#!/bin/bash

# Script to deploy latency simulator from ../2_latency to Cloud Run
# This reuses the existing latency simulator code

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get variables from terraform
PROJECT_ID="rare-karma-480813-i3"
REGION="asia-southeast1"
SERVICE_NAME="app-service"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Cannot get project_id from terraform outputs${NC}"
    exit 1
fi

# Path to latency simulator code
LATENCY_APP_DIR="./2_latency"

if [ ! -d "$LATENCY_APP_DIR" ]; then
    echo -e "${RED}❌ Latency simulator directory not found: $LATENCY_APP_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 Deploying Latency Simulator${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project:  $PROJECT_ID"
echo "  Region:   $REGION"
echo "  Service:  $SERVICE_NAME"
echo "  Source:   $LATENCY_APP_DIR"
echo ""

# Save current directory
CURRENT_DIR=$(pwd)

# Go to latency app directory and deploy
cd $LATENCY_APP_DIR

echo "Deploying Cloud Run service from source..."
gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=100 \
  --cpu 1 \
  --memory 256Mi \
  --min-instances 1 \
  --max-instances 5 \
  --timeout 30s \
  --quiet

# Go back to original directory
cd $CURRENT_DIR

echo ""
echo -e "${GREEN}✅ Latency simulator deployed successfully!${NC}"
echo ""
echo -e "${YELLOW}Service URL:${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --project $PROJECT_ID \
  --format="value(status.url)")
echo "  $SERVICE_URL"

echo ""
echo -e "${YELLOW}Test endpoints:${NC}"
echo "  Health check:  curl $SERVICE_URL/health"
echo "  JSON API:      curl $SERVICE_URL/api/test"
echo "  Web UI:        curl $SERVICE_URL/"
echo ""
echo -e "${YELLOW}Update latency (for testing alert):${NC}"
echo "  # Set to 4 seconds to trigger alert"
echo "  gcloud run services update $SERVICE_NAME --region $REGION --project $PROJECT_ID --set-env-vars LATENCY_MS=4000"
echo ""
echo "  # Reset to normal (100ms)"
echo "  gcloud run services update $SERVICE_NAME --region $REGION --project $PROJECT_ID --set-env-vars LATENCY_MS=100"
