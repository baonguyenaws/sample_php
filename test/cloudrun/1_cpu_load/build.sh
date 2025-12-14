#!/bin/bash

# Build and Push Docker Image to Google Artifact Registry
# Usage: ./build.sh [IMAGE_NAME] [TAG]
# Example: ./build.sh cpu-load-generator v1.0
# Note: Configuration is loaded from .env file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
IMAGE_NAME=${1:-$IMAGE_NAME}
TAG=${2:-$TAG}
FULL_IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🐳 Building and Pushing Docker Image${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project ID:     $PROJECT_ID"
echo "  Region:         $REGION"
echo "  Repository:     $REPO_NAME"
echo "  Image Name:     $IMAGE_NAME"
echo "  Tag:            $TAG"
echo "  Full Path:      $FULL_IMAGE_PATH"
echo ""

# Confirm
read -p "Continue with build and push? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Build cancelled${NC}"
    exit 1
fi

# Step 1: Enable required APIs
echo ""
echo -e "${YELLOW}Step 1: Enabling required APIs...${NC}"
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID --quiet 2>/dev/null || true
echo -e "${GREEN}   ✓ APIs enabled${NC}"

# Step 2: Check and create Artifact Registry repository if not exists
echo ""
echo -e "${YELLOW}Step 2: Checking Artifact Registry repository...${NC}"
if gcloud artifacts repositories describe $REPO_NAME \
  --location=$REGION \
  --project=$PROJECT_ID \
  --quiet &>/dev/null; then
    echo -e "${GREEN}   ✓ Repository '$REPO_NAME' already exists${NC}"
else
    echo -e "${BLUE}   Creating repository '$REPO_NAME'...${NC}"
    gcloud artifacts repositories create $REPO_NAME \
      --repository-format=docker \
      --location=$REGION \
      --description="Docker repository for Cloud Run deployments" \
      --project=$PROJECT_ID \
      --quiet
    echo -e "${GREEN}   ✓ Repository '$REPO_NAME' created successfully${NC}"
fi

# Step 3: Configure Docker authentication
echo ""
echo -e "${YELLOW}Step 3: Configuring Docker authentication...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet 2>/dev/null || true
echo -e "${GREEN}   ✓ Docker authentication configured${NC}"

# Step 4: Build Docker image
echo ""
echo -e "${YELLOW}Step 4: Building Docker image...${NC}"
echo -e "${BLUE}   Building: $FULL_IMAGE_PATH${NC}"

docker build \
  --platform linux/amd64 \
  -t $FULL_IMAGE_PATH \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest \
  .

echo -e "${GREEN}   ✓ Docker image built successfully${NC}"

# Step 5: Push Docker image to Artifact Registry
echo ""
echo -e "${YELLOW}Step 5: Pushing Docker image to Artifact Registry...${NC}"

# Push with specific tag
echo -e "${BLUE}   Pushing: $FULL_IMAGE_PATH${NC}"
docker push $FULL_IMAGE_PATH

# Push latest tag
echo -e "${BLUE}   Pushing: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest${NC}"
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest

echo -e "${GREEN}   ✓ Docker image pushed successfully${NC}"

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Build and Push Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Image Information:${NC}"
echo "  Image Path:     $FULL_IMAGE_PATH"
echo "  Latest Tag:     ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo ""
echo "  # List images in repository"
echo "  gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}"
echo ""
echo "  # View image details"
echo "  gcloud artifacts docker images describe $FULL_IMAGE_PATH"
echo ""
echo "  # Pull image"
echo "  docker pull $FULL_IMAGE_PATH"
echo ""
echo "  # Deploy to Cloud Run"
echo "  gcloud run deploy your-service-name \\"
echo "    --image $FULL_IMAGE_PATH \\"
echo "    --region $REGION \\"
echo "    --project $PROJECT_ID"
echo ""
echo "  # Delete image"
echo "  gcloud artifacts docker images delete $FULL_IMAGE_PATH --quiet"
echo ""
echo -e "${GREEN}========================================${NC}"
