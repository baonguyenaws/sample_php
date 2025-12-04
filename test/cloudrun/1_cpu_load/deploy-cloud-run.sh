#!/bin/bash
set -e

# Deploy CPU Load Generator to Cloud Run
# Usage: ./deploy-cloud-run.sh [VERSION] [REGION] [CPU_TARGET]
# Example: ./deploy-cloud-run.sh v1.0 asia-southeast1 85

VERSION=${1:-v1.0}
REGION=${2:-asia-southeast1}
CPU_TARGET=${3:-85}
DOCKER_HUB_USER=${DOCKER_HUB_USER:-baonv}
IMAGE_NAME="cpu-load-generator"
SERVICE_NAME="cpu-load-${CPU_TARGET}"

echo "🚀 Deploying CPU Load Generator to Cloud Run"
echo "================================"
echo "Docker Hub User: $DOCKER_HUB_USER"
echo "Image: $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION"
echo "Region: $REGION"
echo "CPU Target: ${CPU_TARGET}%"
echo "Service Name: $SERVICE_NAME"
echo "================================"

# Step 1: Build Docker image
echo ""
echo "📦 Step 1: Building Docker image..."
docker build -t $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION .
docker tag $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION $DOCKER_HUB_USER/$IMAGE_NAME:latest

echo "✅ Image built successfully"

# Step 2: Push to Docker Hub
echo ""
echo "📤 Step 2: Pushing to Docker Hub..."
echo "   Pushing $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION"
docker push $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION

echo "   Pushing $DOCKER_HUB_USER/$IMAGE_NAME:latest"
docker push $DOCKER_HUB_USER/$IMAGE_NAME:latest

echo "✅ Image pushed successfully"

# Step 3: Deploy to Cloud Run
echo ""
echo "☁️  Step 3: Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION \
  --region $REGION \
  --set-env-vars CPU_TARGET=$CPU_TARGET,STARTUP_DELAY=5 \
  --timeout 300 \
  --max-instances 1 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --allow-unauthenticated

echo "✅ Deployment complete!"

# Step 4: Get service URL and test
echo ""
echo "🔍 Step 4: Testing service..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

echo ""
echo "================================"
echo "✅ SUCCESS!"
echo "================================"
echo "Service Name: $SERVICE_NAME"
echo "Service URL: $SERVICE_URL"
echo "Region: $REGION"
echo "CPU Target: ${CPU_TARGET}%"
echo ""
echo "Test health check:"
echo "  curl $SERVICE_URL/health"
echo ""
echo "View logs:"
echo "  gcloud run services logs tail $SERVICE_NAME --region $REGION"
echo ""
echo "Delete service:"
echo "  gcloud run services delete $SERVICE_NAME --region $REGION --quiet"
echo "================================"
