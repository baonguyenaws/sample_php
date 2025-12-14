#!/bin/bash

# Deploy Latency Simulator to Google Cloud Run
# Usage: ./deploy-cloudrun.sh [SERVICE_NAME] [LATENCY_MS] [IMAGE_TAG]
# Example: ./deploy-cloudrun.sh latency-simulator-100ms 100 v1.0
# Note: Run ./build.sh first to build and push the image
# Configuration is loaded from .env file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables from .env file
if [ -f .env ]; then
    echo -e "${GREEN}Loading configuration from .env file...${NC}"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create .env file from .env.example${NC}"
    echo "  cp .env.example .env"
    exit 1
fi

# Allow command line arguments to override .env values
SERVICE_NAME=${1:-$SERVICE_NAME}
LATENCY_MS=${2:-$LATENCY_MS}
IMAGE_TAG=${3:-$TAG}
FULL_IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 Deploying Latency Simulator to Cloud Run${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project ID:     $PROJECT_ID"
echo "  Region:         $REGION"
echo "  Service Name:   $SERVICE_NAME"
echo "  Image:          $FULL_IMAGE_PATH"
echo "  Latency:        ${LATENCY_MS}ms"
echo "  CPU:            $CPU"
echo "  Memory:         $MEMORY"
echo "  Min Instances:  $MIN_INSTANCES"
echo "  Max Instances:  $MAX_INSTANCES"
echo ""

# Confirm
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

# Step 1: Verify image exists
echo ""
echo -e "${YELLOW}Step 1: Verifying image exists in Artifact Registry...${NC}"
if gcloud artifacts docker images describe $FULL_IMAGE_PATH --project=$PROJECT_ID &>/dev/null; then
    echo -e "${GREEN}   ✓ Image found: $FULL_IMAGE_PATH${NC}"
else
    echo -e "${RED}   ✗ Image not found: $FULL_IMAGE_PATH${NC}"
    echo -e "${YELLOW}   Please run ./build.sh first to build and push the image${NC}"
    exit 1
fi

# Step 2: Deploy to Cloud Run using pre-built image
echo ""
echo -e "${YELLOW}Step 2: Deploying to Cloud Run using pre-built image...${NC}"
gcloud run deploy $SERVICE_NAME \
  --image $FULL_IMAGE_PATH \
  --region $REGION \
  --project $PROJECT_ID \
  --platform managed \
  --set-env-vars LATENCY_MS=$LATENCY_MS
  --timeout 300 \
  --max-instances $MAX_INSTANCES \
  --min-instances $MIN_INSTANCES \
  --cpu $CPU \
  --memory $MEMORY \
  --port 8080 \
  --cpu-boost \
  --no-cpu-throttling \
  --allow-unauthenticated

echo ""
echo -e "${GREEN}✓ Deployment completed!${NC}"

# Step 3: Get service URL and test
echo ""
echo -e "${YELLOW}Step 3: Getting service information...${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --project $PROJECT_ID \
  --format 'value(status.url)')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Service Information${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Project ID:     $PROJECT_ID"
echo "  Region:         $REGION"
echo "  Service Name:   $SERVICE_NAME"
echo "  Service URL:    $SERVICE_URL"
echo "  Image:          $FULL_IMAGE_PATH"
echo "  Latency:        ${LATENCY_MS}ms"
echo ""
echo -e "${YELLOW}Quick Test:${NC}"
echo "  curl $SERVICE_URL"
echo "  curl $SERVICE_URL/health"
echo "  curl $SERVICE_URL/api/test"
echo ""
echo -e "${YELLOW}View Logs:${NC}"
echo "  gcloud run services logs read $SERVICE_NAME --region $REGION --project $PROJECT_ID --limit 50"
echo ""
echo -e "${YELLOW}Stream Logs:${NC}"
echo "  gcloud run services logs tail $SERVICE_NAME --region $REGION --project $PROJECT_ID"
echo ""
echo -e "${YELLOW}Describe Service:${NC}"
echo "  gcloud run services describe $SERVICE_NAME --region $REGION --project $PROJECT_ID"
echo ""
echo -e "${YELLOW}Delete Service:${NC}"
echo "  gcloud run services delete $SERVICE_NAME --region $REGION --project $PROJECT_ID --quiet"
echo ""

# Wait for service to be fully ready
echo -e "${YELLOW}Waiting 10 seconds for service to be fully ready...${NC}"
sleep 10

# Test the service
echo -e "${YELLOW}Testing service...${NC}"
response=$(curl -s -w "\n%{http_code}" $SERVICE_URL/api/test 2>/dev/null || echo "\nERROR")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✓ Service is responding correctly${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Service returned HTTP $http_code${NC}"
    echo -e "${YELLOW}  Note: Service may need a few moments to fully start${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
