#!/bin/bash
set -e

# Deploy all 3 CPU load services (75%, 85%, 99%) to Cloud Run
# Usage: ./deploy-all-cloud-run.sh [VERSION] [REGION]
# Example: ./deploy-all-cloud-run.sh v1.0 asia-southeast1

VERSION=${1:-v1.0}
REGION=${2:-asia-southeast1}
DOCKER_HUB_USER=${DOCKER_HUB_USER:-baonv}
IMAGE_NAME="cpu-load-generator"

echo "🚀 Deploying ALL CPU Load Services to Cloud Run"
echo "================================"
echo "Docker Hub User: $DOCKER_HUB_USER"
echo "Image: $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION"
echo "Region: $REGION"
echo "Services: cpu-load-75, cpu-load-85, cpu-load-99"
echo "================================"

# Step 1: Build Docker image once
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

# Step 3: Deploy all 3 services
echo ""
echo "☁️  Step 3: Deploying services to Cloud Run..."

# Deploy 75% CPU
echo ""
echo "📊 Deploying cpu-load-75 (75% CPU target)..."
gcloud run deploy cpu-load-75 \
  --image $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION \
  --region $REGION \
  --set-env-vars CPU_TARGET=75,STARTUP_DELAY=5 \
  --timeout 300 \
  --max-instances 1 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --allow-unauthenticated \
  --quiet

echo "✅ cpu-load-75 deployed"

# Deploy 85% CPU
echo ""
echo "📊 Deploying cpu-load-85 (85% CPU target)..."
gcloud run deploy cpu-load-85 \
  --image $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION \
  --region $REGION \
  --set-env-vars CPU_TARGET=85,STARTUP_DELAY=5 \
  --timeout 300 \
  --max-instances 1 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --allow-unauthenticated \
  --quiet

echo "✅ cpu-load-85 deployed"

# Deploy 99% CPU
echo ""
echo "📊 Deploying cpu-load-99 (99% CPU target)..."
gcloud run deploy cpu-load-99 \
  --image $DOCKER_HUB_USER/$IMAGE_NAME:$VERSION \
  --region $REGION \
  --set-env-vars CPU_TARGET=99,STARTUP_DELAY=5 \
  --timeout 300 \
  --max-instances 1 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --allow-unauthenticated \
  --quiet

echo "✅ cpu-load-99 deployed"

# Step 4: Get service URLs
echo ""
echo "🔍 Step 4: Getting service URLs..."

URL_75=$(gcloud run services describe cpu-load-75 --region $REGION --format 'value(status.url)')
URL_85=$(gcloud run services describe cpu-load-85 --region $REGION --format 'value(status.url)')
URL_99=$(gcloud run services describe cpu-load-99 --region $REGION --format 'value(status.url)')

echo ""
echo "================================"
echo "✅ ALL SERVICES DEPLOYED!"
echo "================================"
echo ""
echo "📊 CPU Load 75%:"
echo "   URL: $URL_75"
echo "   Test: curl $URL_75/health"
echo ""
echo "📊 CPU Load 85%:"
echo "   URL: $URL_85"
echo "   Test: curl $URL_85/health"
echo ""
echo "📊 CPU Load 99%:"
echo "   URL: $URL_99"
echo "   Test: curl $URL_99/health"
echo ""
echo "================================"
echo "View logs:"
echo "  gcloud run services logs tail cpu-load-75 --region $REGION"
echo "  gcloud run services logs tail cpu-load-85 --region $REGION"
echo "  gcloud run services logs tail cpu-load-99 --region $REGION"
echo ""
echo "Delete all services:"
echo "  gcloud run services delete cpu-load-75 --region $REGION --quiet"
echo "  gcloud run services delete cpu-load-85 --region $REGION --quiet"
echo "  gcloud run services delete cpu-load-99 --region $REGION --quiet"
echo "================================"

# Optional: Test all services
read -p "🔍 Test all services now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Testing cpu-load-75..."
    curl -s $URL_75/health
    echo ""
    echo ""
    echo "Testing cpu-load-85..."
    curl -s $URL_85/health
    echo ""
    echo ""
    echo "Testing cpu-load-99..."
    curl -s $URL_99/health
    echo ""
    echo ""
    echo "✅ All health checks passed!"
fi
